# Course Validation and Delivery Notes

**Validated against:** one day, 9:00–4:00, 1-hour lunch, 2 breaks
**Last updated:** 2026-11-07
**Status:** Cuts applied. The course now fits in 319 minutes against 330 available, with 11 minutes of float.

---

## 1. Where it stands

| | Before | After |
|---|---|---|
| Total content | 380 min | **319 min** |
| Available instruction time | 330 min | 330 min |
| Over / under | **50 min over** | **11 min under** |
| Deck slides | 49 | 42 |
| Hands-on share | 64% | 65% |

The day now ends at **3:49** with 11 minutes in hand.

### The time budget

| | Minutes |
|---|---|
| 9:00–4:00 | 420 |
| Lunch | −60 |
| 2 breaks @ 15 min | −30 |
| **Available** | **330** |
| Content | 319 |
| **Float** | **11** |

---

## 2. Final schedule

| Time | Min | Block |
|---|---|---|
| 9:00 – 9:07 | 7 | Opening: title, agenda, objectives |
| 9:07 – 9:40 | 33 | Module 1: Introduction to Amazon ECS (11 slides) |
| 9:40 – 9:55 | 15 | **Break** |
| 9:55 – 10:45 | 50 | Lab 1: Deploy Nginx via Console |
| 10:45 – 11:10 | 25 | Module 2: Architecture & Networking (7 slides) |
| 11:10 – 11:40 | 30 | Lab 2: Scaling, Logging, Cleanup |
| 11:40 – 11:45 | 5 | Morning recap |
| 11:45 – 12:45 | 60 | **Lunch** |
| 12:45 – 1:03 | 18 | Module 3: IaC for ECS (5 slides) |
| 1:03 – 1:49 | 46 | Lab 3: Build Your Cloud9 Workstation |
| 1:49 – 2:04 | 15 | **Break** |
| 2:04 – 2:20 | 16 | Module 4: Deploy & Manage with Terraform (4 slides) |
| 2:20 – 3:00 | 40 | Lab 4: Deploy ECS with Terraform |
| 3:00 – 3:42 | 42 | Lab 5: Modify, Scale, Destroy |
| 3:42 – 3:49 | 7 | Closing: recap, next steps |

Morning content 150 min, afternoon content 169 min.

**Lunch is the float.** The morning carries no spare time of its own. If it runs
long, lunch starts late and the afternoon still begins on a full hour — do not
let a late morning eat into the afternoon, which has no slack of its own.

**Break placement.** The first break is at 9:40, before Lab 1 rather than inside
it — the only clean boundary in the morning, and it sends students into a
50-minute lab with a full attention span. The second is at 1:49, between Lab 3
and Module 4.

**Lab 2 cleanup and lunch.** Lab 2's teardown hits dependency-violation errors
while Fargate ENIs release (2–3 min each). Have students start the cleanup, break
for lunch while the ENIs drain, and delete the security groups on return. This
costs no schedule time and removes the most common source of lab frustration.

---

## 3. What changed

### Cloud9 moved from Lab 1 to Lab 3

Labs 1 and 2 are now **entirely console-based** and need no terminal at all.
Students build their workstation at the start of Lab 3, where Terraform first
needs a shell.

| | Before | After |
|---|---|---|
| Lab 1 | Created Cloud9, cloned repo, tested ALB with `curl` | Console only; ALB tested in a browser |
| Lab 2 | `curl` loop from Cloud9 to test load balancing | 15 browser reloads; distribution proved in CloudWatch log streams |
| Lab 3 | "Open the environment you made in Lab 1" | Creates the environment and runs `bootstrap.sh` |

This removes a 6-step provisioning detour from the start of the day — before
students have learned anything about ECS — and puts it where it earns its place.

The Lab 2 change is an improvement on its own terms: the old `curl` loop printed
ten `HTTP 200` lines, which did not actually demonstrate load balancing. Reading
one log stream per task does.

### `scripts/bootstrap.sh`

One command replaces the manual Terraform install:

1. Grows the root EBS volume to 100 GB (`ec2:ModifyVolume`, then `growpart` and `xfs_growfs`)
2. Installs Terraform from HashiCorp's RPM repository
3. Upgrades to AWS CLI v2 (the ECR bonus lab needs `aws ecr get-login-password`)
4. Installs `jq`, `tree`, `git`, `unzip`
5. Installs and starts Docker, adds the student to the `docker` group
6. Enables Terraform tab completion, then prints a verification summary

The script is **idempotent** — every step checks current state first, so it is
safe to re-run. The disk resize is **best-effort by design**: if the environment
lacks `ec2:ModifyVolume`, the script warns and carries on installing tools, since
Labs 3–5 work fine on the 10 GB default. Only the ECR bonus lab needs the space.

Lab 3 Exercise 3.2 Step 1 has students read the script before running it, with a
table explaining each step, so it is a teaching artifact rather than a black box.

### The eight timing cuts

| # | Change | Saved |
|---|---|---|
| 1 | Cloud9 creation out of Lab 1 (moved to Lab 3, scripted) | 15 |
| 2 | Lab 1 Ex 1.7 → "Appendix: Understanding What You Deployed" (take-home) | 10 |
| 3 | Module 1 merged 14 → 11 slides | 12 |
| 4 | "Task Placement and Scheduling" slide cut; Fargate placement folded into the awsvpc slide | 5 |
| 5 | Module 3's three config-walkthrough slides → one "Two Kinds of Block" slide | 12 |
| 6 | Lab 3 Ex 3.5 Step 7 (explore state) dropped — Lab 4 Ex 4.5 covers it properly | 10 |
| 7 | Lab 5 Ex 5.3 (outputs) → `next_steps/terraform-outputs/` | 13 |
| 8 | Two Course Recap slides merged into one; opening fragments removed | 10 |

Plus two contingency cuts applied up front for float:

| Change | Saved |
|---|---|
| Lab 4 Ex 4.5 Steps 3–4 (raw state JSON, reflection discussion) | 5 |
| Lab 5 Ex 5.5 (console re-verification) folded into the destroy exercise as optional | 5 |

### Slide merges in detail

- **"What Are Containers" + "Containers vs VMs"** → one slide. The ASCII VM-vs-container
  diagram was dropped; the comparison table said the same thing in less space.
- **"Amazon ECS Overview" + "ECS Launch Types"** → "Amazon ECS and the Two Launch Types".
  The "Who Uses ECS?" logo-drop was cut.
- **"Task Definitions Deep Dive" + "Container Definition Key Fields"** → one slide.
  The second was a table describing the exact JSON fields shown on the first.
- **Module 3's three "Reading Our ECS Config" slides** → "Reading Our ECS Config:
  Two Kinds of Block". The detail now lives in Lab 4 Ex 4.1 Step 3, which already
  had a table mapping every resource in `main.tf` to its purpose. This also closes
  the 65-minute gap that used to sit between teaching the config and opening it.
- **Two "Course Recap" slides** → one.

---

## 4. Held in reserve

One cut is deliberately **not** applied, because the day fits without it:

> **Lab 1 Ex 1.3 Steps 1–2** — pre-create the two security groups and have
> students inspect rather than build them. Saves ~12 minutes.

Lab 1 is the most likely overrun in the day: 29 console steps across 5 exercises,
plus ~6 minutes of unavoidable waiting (ALB provisioning 2–3 min, task to RUNNING
1–2 min, target healthy 1–2 min). **If Lab 1 is past 10:25 at the end of Exercise
1.2, pre-create the security groups** and have students skip to Step 3. The ALB→task
security chain is already taught on the "Security Groups for ECS" slide, so the
learning outcome survives.

---

## 5. Blocking risk: verify Cloud9 before the day

Labs 3, 4, and 5 depend on students creating a Cloud9 environment.

AWS closed Cloud9 to new customers in **August 2024**. Existing customers keep
access; new AWS accounts cannot create environments, and AWS has said it will add
no new features.

**Impact:** if the training account did not use Cloud9 before August 2024, the
afternoon is dead at Lab 3 Step 1. The morning (Labs 1–2) is now unaffected,
since it is console-only — that is a side benefit of moving Cloud9 to Lab 3.

**Action required:** confirm Cloud9 works in the specific training account. If it
does not, re-platform Labs 3–5 onto:

- **AWS CloudShell** — free, no provisioning, but no persistent IDE and a 1 GB home
  directory. Note it runs **Amazon Linux 2023**, so `bootstrap.sh` will use `dnf`
  (it detects this automatically), and the disk resize does not apply.
- **A plain EC2 instance with SSH** — `bootstrap.sh` runs unchanged.

---

## 6. Pre-delivery checklist

- [ ] **Cloud9 works in the training account** (see §5 — check this first)
- [ ] `ecsTaskExecutionRole` exists in the account
- [ ] Student environments can call `ec2:ModifyVolume`, `ec2:DescribeInstances`,
      and `ec2:DescribeVolumes` — otherwise the disk stays at 10 GB (non-fatal)
- [ ] **Smoke-test `scripts/bootstrap.sh` on one real Cloud9 environment.** It has
      been syntax-checked but not run against live AWS. Confirm the disk reaches
      ~99 GB, Terraform installs, and the summary block prints clean.
- [ ] Deck opens and advances in the room's browser (42 slides)
- [ ] Decide the Lab 1 security-group fallback (§4) before the day, not during it

---

## 7. Smaller issues still open

| Issue | Where | Suggested fix |
|---|---|---|
| **Destroy is practiced before it is taught.** Lab 3 Ex 3.5 Step 7 runs `terraform destroy`; the "Terraform Destroy" slide comes later, before Lab 5 | Deck slide 37, Lab 3 | Move the destroy slide into Module 3, or add one explanatory line to Lab 3 Step 7 |
| **`user0` naming table appears twice** — on the "Complete Resource Map" slide and again on "The user0 Naming Convention" slide | Deck slides 28, 33 | Deliver slide 33 as a 2-minute logistics note, not a 5-minute teach |

### What is already correct

- **Lab interlacing** — all 5 lab-callout slides are preceded by teaching content
  (verified after the merges). Meets the house rule.
- **No "beginner" language** anywhere; README says "Introductory".
- **Reveal.js single-file HTML**, embedded CSS, `data-background-color` lab callouts,
  emoji headers — matches the house template. All tags balanced; no slide overflows
  at presentation width.
- **README figures now reconcile**: 208 lab + 111 theory = 319 total, 65% hands-on.
- **Console-then-Terraform structure** is sound: students build the stack by hand,
  tear it down, then rebuild the same architecture as code. The Lab 5 Ex 5.4
  side-by-side comparison lands because they did both.
- **Bonus labs** now total 120 min across four exercises — the right release valve
  for fast finishers.
