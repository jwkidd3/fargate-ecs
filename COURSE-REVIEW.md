# Course Review: Accuracy, Completeness, Impact

**Reviewed:** 2026-11-07
**Scope:** `main.tf`, all 5 core labs, 4 bonus labs, the 42-slide deck, README
**Method:** technical claims checked against AWS documentation; objectives mapped to content; labs traced end to end

**Verdict:** Technically sound. One wrong table in the deck, seven understated timings, and one bonus-lab defect. The significant finding is not an error but a gap: **the Terraform stack has no logging**, which breaks the course's own "same architecture, two ways" thesis.

---

## Status: fixes applied 2026-11-07

| Finding | Status |
|---|---|
| A1 — health-check table wrong | **Fixed.** `health_check` block added to `main.tf` and to the deck's code sample; the table is now what the code produces. Lab 1 sets the same values in the console. |
| A2 — "1-2 minutes" understated ×7 | **Fixed without editing the labs.** With `healthy_threshold = 2`, time-to-healthy is ~60s, so the existing text is now true on both the console and Terraform paths. |
| A3 — destroy time / `deregistration_delay` | **Fixed.** `deregistration_delay = 30` added, down from the 300s default. |
| A4 — auto-scaling lab fights Terraform | **Fixed.** New Step 3 adds `lifecycle { ignore_changes = [desired_count] }` with an explanation of why. |
| A5 — deck objectives out of sync | **Fixed.** |
| A6 — "AWS provides ecsTaskExecutionRole" | **Fixed.** Now names the managed policy and says the role is created on first use or by an admin. |
| C1 — Terraform stack has no logging | **Fixed.** `aws_cloudwatch_log_group` (7-day retention) plus `logConfiguration` added to `main.tf`. Console and Terraform stacks now match. |
| C2 — Lab 1 never mentions logging | **Fixed.** Lab 1 Ex 1.2 Step 3 points at the Logging toggle and names the log group it creates. |
| C6 — no `fmt` / `validate` | **Fixed.** New Lab 4 Ex 4.3 Step 1 runs both before `init`. |
| I1 — students never author Terraform | **Partly addressed.** The `write-terraform-variables` bonus lab now has students declare a variable and refactor all nine names by hand. Still a bonus, not core. |
| C3 — no assessment | Open — needs ~8 min the schedule does not have |
| C4 — no production-vs-lab security framing | Open — ~2 min, fits the float |
| C5 — no cost awareness | Partly addressed: Lab 2's new log-group step explains retention and per-GB billing |
| I3 — nothing ever fails | Open — ~5 min, best impact-per-minute change available |

### Knock-on change: the log group collision

Adding a Terraform-managed `/ecs/userX-task` created a conflict with the log group the
console auto-creates in Lab 1. Lab 2 previously said it was "OK to leave", which would
have made `terraform apply` fail with `ResourceAlreadyExistsException` in Lab 4. Lab 2
now has an explicit Step 8 to delete it, and Lab 4 carries a troubleshooting row for
the case where someone skips it.

### Verification performed

All three configurations were checked with `terraform validate` against the real AWS
provider schema:

- `lab-exercises/lab04/main.tf` with the log group, `logConfiguration`, `health_check` and `deregistration_delay` — **valid**
- The same file after the `write-terraform-variables` refactor, with `variables.tf` — **valid**
- The same file with the auto-scaling target, policy and `lifecycle` block — **valid**

The variable validation rule was exercised directly: `user5` accepted; `Bob`, `USER5`,
`user` and an empty string all rejected.

`terraform fmt` reports only pre-existing alignment issues, none in the added blocks —
which means Lab 4's new `fmt` step has something visible to do.

Deck re-rendered: 42 slides, tags balanced, 5 lab callouts intact, nothing overflows at
presentation width.

---

---

## 1. Accuracy

### A1 — The health-check table is wrong, and contradicts the code beside it

`presentations/ecs_fargate.html:1058-1059`, slide "Target Groups for Fargate":

| Setting | Deck claims | AWS default |
|---|---|---|
| Healthy threshold | **2** | **5** |
| Unhealthy threshold | **3** | **2** |
| Interval | 30s | 30s ✓ |
| Path | `/` | `/` ✓ |

Both thresholds are wrong, and they are inverted relative to reality. Worse, the
same slide shows an `aws_lb_target_group` block with **no `health_check` block**,
so the AWS defaults are what students actually get. The table describes something
the code on that slide does not produce.

> Source: [ALB target group health check settings](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html) — "HealthyThresholdCount … The default is 5. UnhealthyThresholdCount … The default is 2."

**Fix:** either correct the table to 5/2, or add an explicit `health_check` block
to `main.tf` that produces 2/3. The second is better — it makes the slide true,
teaches an important block, and cuts time-to-healthy from 150s to 60s.

### A2 — "1-2 minutes to healthy" is understated in seven places

Healthy threshold 5 × 30s interval = **150 seconds minimum** before a target is
marked healthy, and that clock starts only once the container is serving. Realistic
end-to-end is 2-3 minutes.

| File | Line |
|---|---|
| `lab-exercises/lab01/README.md` | 290, 298 |
| `lab-exercises/lab02/README.md` | 50, 56 |
| `lab-exercises/lab04/README.md` | 159, 238 |
| `lab-exercises/lab05/README.md` | 82 |

This is the root cause of the `503` confusion that four separate troubleshooting
entries then exist to mop up. Fixing A1 with an explicit `health_check` block makes
the existing "1-2 minutes" text true instead of requiring seven edits.

### A3 — Destroy time understated; `deregistration_delay` is never set

`lab-exercises/lab05/README.md:209` says `terraform destroy` "typically takes
**2-3 minutes**". The target group's `deregistration_delay` defaults to **300
seconds** and `main.tf` does not override it, so draining targets alone can hold
the teardown for 5 minutes. Realistic: 4-6 minutes.

> Source: [TargetGroupAttribute](https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_TargetGroupAttribute.html) — "`deregistration_delay.timeout_seconds` … The default value is 300 seconds."

**Fix:** add `deregistration_delay = 30` to the target group. This is a one-line
change that makes Lab 5 noticeably snappier, makes the stated timing true, and is a
genuinely useful production detail to teach.

### A4 — The auto-scaling bonus lab will fight Terraform

`next_steps/auto-scaling/README.md` adds an `aws_appautoscaling_target` and a
target-tracking policy, but never adds:

```hcl
lifecycle {
  ignore_changes = [desired_count]
}
```

to the `aws_ecs_service`. Once the policy scales the service to 4 tasks, the next
`terraform plan` reports `desired_count: 4 -> 1` and `apply` undoes the autoscaler.
The lab has students watch scaling happen and then leaves them with a configuration
that silently reverts it. This is the best-known Terraform/ECS autoscaling pitfall
and it belongs in a lab that teaches autoscaling.

### A5 — Deck objectives slide is out of sync with the README

`presentations/ecs_fargate.html:515` still reads "Install and configure Terraform on
Amazon Linux". The README now reads "Build a working Cloud9 workstation with a
single bootstrap script". Introduced by the Lab 3 restructure; missed on that pass.

### A6 — "AWS provides: `ecsTaskExecutionRole`" oversells it

The IAM Roles slide says AWS provides the role. AWS provides the **managed policy**
(`AmazonECSTaskExecutionRolePolicy`); the role itself is created on first use through
the console wizard, or by an administrator. The README correctly lists it as an
instructor prerequisite, so the slide is the odd one out. Minor, but students who
try this in their own account will hit it.

### Verified accurate — no action needed

Checked against AWS documentation and found correct:

- **Fargate CPU/memory table** — matches the published combinations exactly (256 → 512 MiB/1 GB/2 GB; 512 → 1-4 GB; 1024 → 2-8 GB; 2048 → 4-16 GB; 4096 → 8-30 GB)
- **Lab 5's 512/1024 modification** — a valid Fargate combination, so the lab will not fail
- **Security group pattern** — ALB SG open to `0.0.0.0/0:80`, task SG referencing the ALB SG; the slide matches `main.tf` exactly
- **Execution role vs task role** — the distinction is correct and clearly drawn, including Secrets Manager retrieval via the execution role
- **CloudWatch slide** — `awslogs` driver, log group/stream naming, Container Insights, EventBridge task state changes all correct
- **In-place vs replacement semantics** — `desired_count` updates in place; CPU/memory forces a new task definition revision. Correct.
- **ECR bonus lab** — `aws ecr get-login-password | docker login --password-stdin` is correct v2 syntax (and `bootstrap.sh` now installs v2, so it will work)
- **Auto-scaling resource shape** — `ecs:service:DesiredCount`, namespace `ecs`, `ECSServiceAverageCPUUtilization` all correct
- **Lab 3's inline config** — valid and minimal

---

## 2. Completeness

### C1 — The Terraform stack has no logging *(most important finding)*

`lab-exercises/lab04/main.tf` has no `logConfiguration` in its container definition
and creates no log group. The consequences compound:

| | Console stack (Labs 1-2) | Terraform stack (Labs 4-5) |
|---|---|---|
| Logs to CloudWatch | **Yes** | **No** |
| Students can read access logs | Yes (Lab 2 Ex 2.2) | Nothing to read |

So:

1. **The course's central thesis breaks.** "Same architecture, two approaches" is the
   organising idea and the payoff of Lab 5's comparison. The two stacks are not the
   same — the Terraform one is strictly less capable.
2. **A taught capability silently disappears after lunch.** Lab 2 spends an exercise
   teaching students to read per-task log streams. Nothing in the afternoon has logs.
3. **The recap claims it anyway.** The Course Recap slide lists "Scaling & Logging -
   desired count, CloudWatch Logs" among what was covered.
4. **It is parked in a bonus lab** (`write-terraform-resource`), which most students
   will not reach.

**Fix:** add the log group and `logConfiguration` to `main.tf`. That restores the
parity the course is built on. The bonus lab then needs a new authoring target — a
task role with S3 access, or the `health_check` block from A1, both of which are
better "write it yourself" exercises than re-deriving something the main config
already has.

### C2 — Lab 1 never tells students logging was configured

Lab 1 Ex 1.2 Step 3 says "Leave all other container settings at their defaults." The
ECS console enables log collection by default, which is why `/ecs/userX-task` exists
for Lab 2 to explore. But Lab 2 Ex 2.2 Step 4 then says "The awslogs driver **was
configured** in your task definition with these parameters" — describing a decision
students never saw being made. One sentence in Lab 1 pointing at the Logging section
closes the loop.

### C3 — Nothing assesses whether the outcomes were met

Ten stated learning outcomes, no knowledge checks, no quiz, no capstone, no
self-check beyond "did the page load". Normal for a one-day course, but it means
neither the student nor the instructor can tell what landed. Three or four
two-minute knowledge-check slides at module boundaries would cost ~8 minutes — which
the schedule does not currently have (see §4).

### C4 — No production-vs-lab framing on security

The course deploys into the default VPC, on public subnets, with
`assign_public_ip = true` and tasks directly addressable from the internet. Real ECS
deployments put tasks in **private** subnets with the ALB in public ones. The phrase
"private subnet" appears nowhere in the deck or the labs; `assign_public_ip` appears
once, inside a code block, unexplained.

The security group slide does teach the ALB→task chain well. The missing piece is one
line saying this is a lab shortcut, not the production shape. Without it, students
will reproduce the lab topology at work.

### C5 — Essentially no cost awareness

Two incidental mentions across the whole course. An ALB is roughly $16-18/month
before LCU charges, and it runs whether or not anyone uses it. Lab 2's cleanup is
labelled **MANDATORY** but never says why in money terms, which is exactly the
motivation that makes students actually do it — and the habit that matters most once
they are working in a real account.

### C6 — `terraform fmt` and `terraform validate` are absent

`validate` appears only in a troubleshooting row; `fmt` not at all. Both are
one-liners, both are things practitioners run constantly, and both fit naturally into
Lab 4 between the `sed` and the `init`.

### Objectives coverage — otherwise complete

All ten stated outcomes are taught and practiced. The only knowledge-only outcome is
"compare Fargate and EC2 launch types", which is appropriate — there is nothing to
practice in a Fargate-only course.

---

## 3. Impact

### I1 — Students never author Terraform in the core course

This is the biggest limitation on what students can do on Monday morning.

| Lab | What students actually do |
|---|---|
| Lab 3 | Type a 15-line config from the page |
| Lab 4 | `sed -i 's/user0/userX/g' main.tf` |
| Lab 5 | Change `1` to `3`, change `256` to `512` |

Every from-scratch authoring exercise is in `next_steps/`. A student completing the
core course can **read and modify** Terraform but has never **composed** a resource
from the provider documentation — which is the actual job. The stated outcome is
carefully worded ("Read and understand an ECS Terraform configuration"), so the course
is honest about this. But it caps the impact.

### I2 — The build-it-twice structure is the course's real strength

Console in the morning, the same architecture as code in the afternoon, with an
explicit side-by-side in Lab 5 Ex 5.4. This is genuinely good instructional design.

The sharpest part is **Lab 2's mandatory 8-step teardown**. Making students feel the
dependency-ordered cleanup pain — ENIs draining, security groups refusing to delete —
is precisely what makes `terraform destroy` land as a revelation rather than a
command. Keep that exactly as it is, including the frustration.

### I3 — Nothing ever fails, so diagnosis is never practiced

Every lab is a happy path. The troubleshooting sections are good reference material,
but they are read-if-stuck, not exercised. Diagnosis is arguably the highest-value
ECS skill — the gap between "I deployed nginx" and "I can run this" is almost entirely
about reading events, health checks, and logs when something is wrong.

A deliberate 5-minute break-it moment would convert passive documentation into
practiced skill. The cheapest version: in Lab 1, after the service is healthy, have
students remove the ECS security group's ingress rule, watch the target go unhealthy
in the console, read the failure, and put it back. It teaches the ALB→task chain by
breaking it, and it reuses infrastructure that is already deployed.

### I4 — Fargate-only is the right scope call

Cutting EC2 placement strategies left the course coherent. There is no half-taught
second launch type competing for attention.

### I5 — The bonus labs carry disproportionate value

Logging, custom images from ECR, and autoscaling are the three things that make this
production-relevant, and all three are optional. Most students will not reach them.
C1 fixes the worst of this by pulling logging into the core.

---

## 4. The timing trade-off

The course currently runs 319 minutes against 330 available, with 11 minutes of float.
The recommendations here are not all free:

| Fix | Time cost |
|---|---|
| A1-A6, C1, C2, C6 | **0 min** — corrections and config changes, no new content |
| C4 (production framing) | ~2 min (a callout on an existing slide) |
| C5 (cost awareness) | ~2 min (a line in Lab 2 plus one slide note) |
| I3 (break-it moment) | ~5 min |
| C3 (knowledge checks) | ~8 min |
| I1 (authoring exercise) | ~15 min — does not fit without a cut |

The first four fit inside the 11-minute float. C3 and I1 do not. If authoring matters
more than the Lab 3 cluster-lifecycle exercise (Ex 3.5), that is the natural trade:
Lab 4 already re-teaches `init`/`plan`/`apply`/`destroy`, so Ex 3.5 is the most
redundant 20 minutes in the course.

---

## 5. Recommended order

1. **Add logging to `main.tf`** (C1) — restores the course's thesis; repoint the
   `write-terraform-resource` bonus at a task role or the health-check block
2. **Add `health_check` and `deregistration_delay` to the target group** (A1, A3) —
   two blocks that make the deck true, make the stated timings true, and speed up Lab 5
3. **Fix the auto-scaling lab's `lifecycle` block** (A4) — it currently teaches a
   configuration that undoes itself
4. **Sync the deck objectives slide** (A5) and soften the `ecsTaskExecutionRole`
   claim (A6)
5. **Add the production-shape and cost callouts** (C4, C5) — ~4 minutes, high
   real-world value, fits the float
6. **Consider the break-it moment** (I3) — 5 minutes, the best impact-per-minute
   change available
7. **Revisit `terraform fmt`/`validate`** (C6) and Lab 1's logging note (C2) — free

Items 1-4 and 7 are corrections and cost no schedule time. Items 5-6 consume most of
the float. Item I1 (authoring) needs a decision about Lab 3 Ex 3.5 first.
