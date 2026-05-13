# DATABASE SCHEMA — `ceit_db`

> **Engine:** MariaDB 10.4 · **Charset:** utf8mb4_unicode_ci  
> **Generated:** 2026-05-13 · **Tables:** 33 · **Source:** `ceit_db.sql`

---

## Table of Contents

1. [Overview](#overview)
2. [Entity Relationship Map](#entity-relationship-map)
3. [Table Reference](#table-reference)
   - [Academic Structure](#academic-structure)
   - [Location](#location)
   - [People — Students](#people--students)
   - [People — Teachers](#people--teachers)
   - [People — Users & Auth](#people--users--auth)
   - [Academic Delivery](#academic-delivery)
   - [Assessment & Evaluation](#assessment--evaluation)
   - [Notifications & Devices](#notifications--devices)
   - [Room Management](#room-management)
4. [Foreign Key Relationships](#foreign-key-relationships)
5. [AUTO_INCREMENT Status](#auto_increment-status)

---

## Overview

`ceit_db` is the backend database for the **CEIT (College of Engineering and Information Technology)** management system. It covers:

- Academic programme hierarchy (major → curriculum → subject group → subject)
- Organisational hierarchy (department → division)
- Location hierarchy (province → district → village)
- Student lifecycle (registration → group → enrolment → grade)
- Teacher management and timetabling
- Online examination (question bank → open exam → answers)
- Teacher evaluation by students
- User authentication with role-based access control (RBAC)
- Push notification delivery

---

## Entity Relationship Map

```
LOCATION                          ACADEMIC STRUCTURE
──────────                        ──────────────────────────────────────────
provinces                         major
  └─ districts                      └─ curriculums
       └─ villages                        └─ student_groups ──┐
                                          └─ subjects         │
ORGANISATION                                   │              │
─────────────                         subject_group           │
departments                                                    │
  └─ divisions                        semaster                 │
                                           │                  │
PEOPLE                                     └──── study_plan ──┘
──────                                             │      │
teachers ───────────────────────────────────────── ┘      │
  (dept_id, division_id)                                   │
  └─ users.teacher_id                           students ──┘
                                                   │
students                                           └─ enrollments
  (std_type_id → student_type)                     └─ std_family
  (std_group_id → student_groups)                  └─ evaluation_results
  (curri_id → curriculums)
  (cur_village/born_village → villages)    EXAMINATION
  └─ users.std_id                          ───────────
                                           stock_question ─── stock_answers
AUTH / RBAC                                     └─ open_exam
──────────                                           └─ exam_answers
users
  └─ user_roles → roles
  └─ user_devices
  └─ user_noti  → notifications
       └─ user_noti

ROOM MANAGEMENT
───────────────
rooms
  └─ study_plan.room_id
  └─ room_booking
```

---

## Table Reference

### Academic Structure

---

#### `major`
Top-level academic discipline.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `major_code` | varchar(11) | NO | | e.g. `CE`, `IT` |
| `major_name_lao` | varchar(255) | NO | | Lao name |
| `major_name_eng` | varchar(255) | YES | NULL | English name |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `curriculums`
Degree programme under a major (e.g. Computer Engineering 2026).

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `curri_code` | varchar(11) | NO | | e.g. `CUR2026CE` |
| `curri_name_lao` | varchar(255) | NO | | |
| `curri_name_eng` | varchar(255) | YES | NULL | |
| `curri_name_lao_abb` | varchar(255) | YES | NULL | Abbreviation |
| `major_id` | int(11) | NO | | FK → `major.id` CASCADE |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `subject_group`
Category of subjects (General, Core, Elective, Lab, etc.).

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `group_code` | varchar(11) | NO | | e.g. `CORE`, `GEN`, `LAB` |
| `group_name_lao` | varchar(255) | NO | | |
| `group_name_eng` | varchar(255) | YES | NULL | |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `subjects`
Individual courses/modules within a curriculum.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `curri_id` | int(11) | NO | | FK → `curriculums.id` CASCADE |
| `group_id` | int(11) | NO | | FK → `subject_group.id` CASCADE |
| `subject_code` | varchar(11) | NO | | e.g. `CS101` |
| `name_lao` | varchar(100) | NO | | |
| `name_eng` | varchar(100) | YES | NULL | |
| `credit` | int(11) | NO | | Credit hours |
| `lab_hours` | int(11) | NO | | Lab contact hours |
| `lecture_hours` | int(11) | NO | | Lecture contact hours |
| `practic_hours` | int(11) | NO | | Practical contact hours |
| `levelingroup` | int(11) | NO | | Order within subject group |
| `levelinterm` | int(11) | NO | | Order within term |
| `term` | int(11) | NO | | Semester number (1 or 2) |
| `year` | int(11) | NO | | Academic year |
| `status` | int(11) | NO | 1 | 1 = active, 0 = inactive |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `semaster`
Academic semester / term periods.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `semaster_code` | varchar(11) | NO | | e.g. `SEM2025-2` |
| `year` | int(11) | NO | | Academic year |
| `term` | int(11) | NO | | 1 or 2 |
| `start_date` | datetime | YES | NULL | |
| `end_date` | datetime | YES | NULL | |
| `status` | int(11) | NO | 1 | 1 = current, 0 = past |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `student_groups`
Class sections belonging to a curriculum.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `std_group_code` | varchar(11) | NO | | e.g. `CS22A` |
| `std_group_name` | varchar(255) | NO | | Display name |
| `curriculum_id` | int(11) | NO | | FK → `curriculums.id` CASCADE |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `student_type`
Classification of students (Regular, International, Part-time, etc.).

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `std_type_code` | varchar(6) | NO | | e.g. `REG`, `INT` |
| `std_type_name_lao` | varchar(255) | NO | | |
| `std_type_name_eng` | varchar(255) | NO | | |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `study_plan`
Timetable entry linking a subject, group, teacher, room, and semester.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `semaster_id` | int(11) | NO | | FK → `semaster.id` CASCADE |
| `subject_id` | int(11) | NO | | FK → `subjects.id` CASCADE |
| `std_group_id` | int(11) | NO | | FK → `student_groups.id` CASCADE |
| `teacher_id` | int(11) | NO | | FK → `teachers.id` CASCADE |
| `room_id` | int(11) | YES | NULL | FK → `rooms.id` SET NULL |
| `day_of_week` | varchar(10) | YES | NULL | e.g. `Monday` |
| `start_time` | varchar(10) | YES | NULL | e.g. `08:00` |
| `end_time` | varchar(10) | YES | NULL | e.g. `10:00` |
| `attech_link` | text | YES | NULL | Attachment / course material URL |
| `score_file` | text | YES | NULL | Grade upload file path |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

### Location

---

#### `provinces`
Lao PDR provinces / capitals.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `province_code` | varchar(11) | NO | | |
| `province_name_lao` | varchar(255) | NO | | |
| `province_name_eng` | varchar(255) | YES | NULL | |
| `created_at` | datetime(3) | YES | NULL | |
| `updated_at` | datetime(3) | YES | NULL | |
| `deleted_at` | datetime(3) | YES | NULL | Soft delete |

---

#### `districts`
Districts within a province.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `district_code` | varchar(11) | NO | | |
| `district_name_lao` | varchar(255) | NO | | |
| `district_name_eng` | varchar(255) | YES | NULL | |
| `province_id` | int(11) | NO | | FK → `provinces.id` CASCADE |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `villages`
Villages within a district.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `village_code` | varchar(11) | NO | | |
| `village_name_lao` | varchar(255) | NO | | |
| `village_name_eng` | varchar(255) | YES | NULL | |
| `district_id` | int(11) | NO | | FK → `districts.id` CASCADE |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

### People — Students

---

#### `students`
Student personal and academic profile.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `std_code` | varchar(15) | NO | | Student ID number |
| `std_type_id` | int(11) | NO | | FK → `student_type.id` CASCADE |
| `std_group_id` | int(11) | YES | NULL | FK → `student_groups.id` SET NULL |
| `curri_id` | int(11) | NO | | FK → `curriculums.id` CASCADE |
| `name_lao` | varchar(100) | NO | | First name (Lao) |
| `surname_lao` | varchar(100) | YES | NULL | Surname (Lao) |
| `name_eng` | varchar(100) | NO | | First name (English) |
| `surname_eng` | varchar(100) | YES | NULL | Surname (English) |
| `name_title` | varchar(6) | NO | | Mr / Ms / Mrs |
| `gender` | varchar(6) | NO | | Male / Female |
| `dateofbirth` | datetime | NO | | |
| `photo` | varchar(255) | YES | NULL | Profile photo path |
| `cur_village` | int(11) | YES | NULL | FK → `villages.id` (current address) |
| `born_village` | int(11) | YES | NULL | FK → `villages.id` (birthplace) |
| `telephone` | varchar(20) | YES | NULL | |
| `email` | varchar(40) | YES | NULL | |
| `nationality` | varchar(40) | YES | NULL | |
| `ethnic` | varchar(40) | YES | NULL | |
| `race` | varchar(40) | YES | NULL | |
| `tribe` | varchar(40) | YES | NULL | |
| `job_title` | varchar(40) | YES | NULL | Employment (if any) |
| `school` | varchar(80) | YES | NULL | Previous school |
| `religion` | varchar(40) | YES | NULL | |
| `marital_status` | varchar(40) | YES | NULL | |
| `health_status` | varchar(40) | YES | NULL | |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `std_family`
Family/guardian contacts for a student.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `std_id` | int(11) | NO | | FK → `students.id` CASCADE |
| `name` | varchar(100) | NO | | Guardian full name |
| `arg` | int(11) | YES | NULL | Age |
| `village_id` | int(11) | YES | NULL | FK → `villages.id` SET NULL |
| `job_title` | varchar(100) | YES | NULL | |
| `office` | varchar(100) | YES | NULL | Workplace |
| `telephone` | varchar(20) | YES | NULL | |
| `relation` | varchar(20) | YES | NULL | Father / Mother / Sibling … |
| `emergency_level` | int(11) | YES | NULL | 1 = primary contact |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `enrollments`
Student enrolment in a study-plan slot, with scores and grade.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `study_plan_id` | int(11) | NO | | FK → `study_plan.id` CASCADE |
| `std_id` | int(11) | NO | | FK → `students.id` CASCADE |
| `status` | enum('Enrolled','Dropped') | YES | `Enrolled` | |
| `attend_score` | int(11) | YES | NULL | Attendance score (max 10) |
| `assignment_score` | int(11) | YES | NULL | Assignment score (max 15) |
| `midterm_score` | int(11) | YES | NULL | Mid-term score (max 30) |
| `final_score` | int(11) | YES | NULL | Final score (max 45) |
| `grade` | varchar(3) | YES | NULL | A / B+ / B / C+ / C / D / F |
| `remark` | varchar(255) | YES | NULL | |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

### People — Teachers

---

#### `departments`
Academic departments within the faculty.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `department_code` | varchar(11) | NO | | |
| `dept_name_lao` | varchar(255) | NO | | |
| `dept_name_eng` | varchar(255) | YES | NULL | |
| `telephone` | varchar(255) | YES | NULL | |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `divisions`
Divisions / units within a department.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `division_code` | varchar(11) | NO | | |
| `division_name_lao` | varchar(255) | NO | | |
| `division_name_eng` | varchar(255) | YES | NULL | |
| `dept_id` | int(11) | NO | | FK → `departments.id` CASCADE |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `teachers`
Teacher / lecturer personal and departmental profile.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `dept_id` | int(11) | NO | | FK → `departments.id` CASCADE |
| `teacher_code` | varchar(15) | NO | | e.g. `TCH001` |
| `name_lao` | varchar(50) | NO | | |
| `surname_lao` | varchar(50) | NO | | |
| `name_eng` | varchar(50) | NO | | |
| `surname_eng` | varchar(50) | YES | NULL | |
| `gender` | varchar(6) | NO | | |
| `dateofbirth` | datetime | NO | | |
| `photo` | varchar(255) | YES | NULL | |
| `cur_village` | int(11) | NO | | FK → `villages.id` (no FK constraint) |
| `born_village` | int(11) | NO | | FK → `villages.id` (no FK constraint) |
| `telephone` | varchar(20) | YES | NULL | |
| `email` | varchar(40) | YES | NULL | |
| `nationality` | varchar(40) | YES | NULL | |
| `ethnic` | varchar(40) | YES | NULL | |
| `race` | varchar(40) | YES | NULL | |
| `tribe` | varchar(40) | YES | NULL | |
| `religion` | varchar(40) | YES | NULL | |
| `marital_status` | varchar(40) | YES | NULL | |
| `health_status` | varchar(40) | YES | NULL | |
| `division_id` | int(11) | YES | NULL | FK → `divisions.id` SET NULL |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

### People — Users & Auth

---

#### `users`
System login accounts (linked to either a student or teacher).

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `username` | varchar(25) | NO | | **UNIQUE** |
| `email` | varchar(50) | YES | NULL | |
| `password` | varchar(100) | NO | | bcrypt hash |
| `std_id` | int(11) | YES | NULL | FK → `students.id` SET NULL |
| `teacher_id` | int(11) | YES | NULL | FK → `teachers.id` SET NULL |
| `active` | int(11) | YES | 1 | 1 = active, 0 = disabled |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

> **Note:** Either `std_id` or `teacher_id` should be set (not both), unless the account is a pure admin.

---

#### `roles`
System roles (Administrator, Teacher, Student, Staff, etc.).

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `name` | varchar(25) | NO | | |
| `description` | varchar(50) | NO | | |
| `guard_name` | varchar(25) | YES | NULL | e.g. `web`, `api` |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `permissions`
Granular system permissions (e.g. `view_students`, `manage_exams`).

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `name` | varchar(25) | NO | | e.g. `view_students` |
| `description` | varchar(50) | NO | | |
| `guard_name` | varchar(25) | YES | NULL | |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `permission_roles`
Many-to-many: permissions granted to roles.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `permission_id` | int(11) | NO | | FK → `permissions.id` CASCADE |
| `role_id` | int(11) | NO | | FK → `roles.id` CASCADE |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `user_roles`
Many-to-many: roles assigned to users.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `role_id` | int(11) | NO | | FK → `roles.id` CASCADE |
| `user_id` | int(11) | NO | | FK → `users.id` CASCADE |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `user_devices`
Push-notification device tokens per user (mobile apps).

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `user_id` | int(11) | NO | | FK → `users.id` CASCADE |
| `device_token` | varchar(255) | NO | | FCM token |
| `platform` | varchar(20) | YES | NULL | `android` / `ios` |
| `is_active` | int(11) | NO | 1 | |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |

---

### Academic Delivery

---

#### `study_plan`
*(Documented under [Academic Structure](#academic-structure) above.)*

---

#### `enrollments`
*(Documented under [People — Students](#people--students) above.)*

---

### Assessment & Evaluation

---

#### `evaluation_questions`
Question bank for student evaluation of teachers.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `eva_question_id` | int(11) | NO | AUTO_INCREMENT | PK |
| `question` | text | NO | | Evaluation question text |
| `category` | varchar(100) | YES | NULL | e.g. `Teaching Quality`, `Punctuality` |
| `is_active` | int(11) | NO | 1 | 1 = shown, 0 = hidden |
| `create_at` | datetime | YES | current_timestamp() | |

---

#### `evaluation_results`
Student responses to evaluation questions for a specific study plan.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `eva_results_id` | int(11) | NO | AUTO_INCREMENT | PK |
| `study_plan_id` | int(11) | NO | | FK → `study_plan.id` CASCADE |
| `student_id` | int(11) | NO | | FK → `students.id` CASCADE |
| `eva_question_id` | int(11) | NO | | FK → `evaluation_questions.eva_question_id` CASCADE |
| `score` | int(11) | YES | NULL | 0–10 |
| `comment` | text | YES | NULL | Optional free-text comment |
| `create_at` | datetime | YES | current_timestamp() | |

---

#### `stock_question`
Online exam question bank.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `q_statement` | text | NO | | Question body |
| `level` | int(11) | NO | | Difficulty: 1 = easy, 2 = medium, 3 = hard |
| `actived` | int(11) | NO | 1 | 1 = active |
| `sub_id` | int(11) | YES | NULL | FK → `subjects.id` SET NULL |
| `anwser_type` | varchar(10) | YES | NULL | `MCQ` / `TF` / `SHORT` |
| `onwer` | int(11) | YES | NULL | FK → `users.id` SET NULL (author) |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `stock_answers`
Answer choices for each question in the question bank.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `op_statement` | text | NO | | Answer option text |
| `correct_ans` | int(11) | NO | | 1 = correct, 0 = wrong |
| `q_id` | int(11) | YES | NULL | FK → `stock_question.id` CASCADE |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `open_exam`
Exam session opened for a specific study plan (timed window).

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `num_question` | varchar(20) | NO | | Number of questions drawn |
| `time_duration` | varchar(50) | NO | | e.g. `60 min` |
| `open_time` | datetime | YES | NULL | Exam start datetime |
| `st_plan_id` | int(11) | YES | NULL | FK → `study_plan.id` SET NULL |
| `close_time` | datetime | YES | NULL | Exam end datetime |
| `inactive` | int(11) | YES | 0 | 1 = exam closed early |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `exam_answers`
Individual student answers submitted during an open exam.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `user_id` | int(11) | NO | | FK → `users.id` CASCADE |
| `q_id` | int(11) | NO | | FK → `stock_question.id` CASCADE |
| `open_ex_id` | int(11) | YES | NULL | FK → `open_exam.id` SET NULL |
| `answer` | varchar(25) | YES | NULL | Selected option label (e.g. `A`) |
| `scored` | int(11) | YES | NULL | 1 = correct, 0 = wrong |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

### Notifications & Devices

---

#### `notifications`
System-wide notification messages.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `noti_id` | int(11) | NO | AUTO_INCREMENT | PK |
| `title` | varchar(255) | NO | | |
| `message` | text | NO | | |
| `type` | varchar(50) | YES | NULL | `info` / `warning` / `error` |
| `is_read` | int(11) | NO | 0 | Global read flag |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |

---

#### `user_noti`
Per-user notification delivery and read status.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `user_id` | int(11) | NO | | FK → `users.id` CASCADE |
| `noti_id` | int(11) | NO | | FK → `notifications.noti_id` CASCADE |
| `is_read` | int(11) | NO | 0 | 0 = unread, 1 = read |
| `create_at` | datetime | YES | current_timestamp() | |

---

### Room Management

---

#### `rooms`
Physical classrooms and labs.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `id` | int(11) | NO | AUTO_INCREMENT | PK |
| `room_code` | varchar(11) | NO | | e.g. `A301`, `LAB1` |
| `capacity` | int(11) | NO | | Max occupancy |
| `description` | text | YES | NULL | Room description |
| `status` | int(11) | NO | 1 | 1 = available |
| `created_at` | datetime | YES | current_timestamp() | |
| `updated_at` | datetime | YES | current_timestamp() ON UPDATE | |
| `deleted_at` | datetime | YES | NULL | Soft delete |

---

#### `room_booking`
Room reservation requests from staff or teachers.

| Column | Type | Null | Default | Notes |
|--------|------|------|---------|-------|
| `booking_id` | int(11) | NO | AUTO_INCREMENT | PK |
| `room_id` | int(11) | NO | | FK → `rooms.id` CASCADE |
| `user_id` | int(11) | NO | | FK → `users.id` CASCADE |
| `booking_date` | datetime | NO | | Date of booking |
| `start_time` | varchar(20) | NO | | e.g. `08:00` |
| `end_time` | varchar(20) | NO | | e.g. `10:00` |
| `purpose` | varchar(255) | YES | NULL | e.g. `Lab Session` |
| `status` | varchar(20) | NO | `pending` | `pending` / `approved` / `rejected` |
| `create_at` | datetime | YES | current_timestamp() | |

---

## Foreign Key Relationships

| Constraint | Child Table → Column | Parent Table → Column | On Delete |
|------------|---------------------|----------------------|-----------|
| `curriculums_ibfk_1` | `curriculums.major_id` | `major.id` | CASCADE |
| `districts_ibfk_1` | `districts.province_id` | `provinces.id` | CASCADE |
| `divisions_ibfk_1` | `divisions.dept_id` | `departments.id` | CASCADE |
| `enrollments_ibfk_1` | `enrollments.study_plan_id` | `study_plan.id` | CASCADE |
| `enrollments_ibfk_2` | `enrollments.std_id` | `students.id` | CASCADE |
| `evaluation_results_ibfk_1` | `evaluation_results.study_plan_id` | `study_plan.id` | CASCADE |
| `evaluation_results_ibfk_2` | `evaluation_results.student_id` | `students.id` | CASCADE |
| `evaluation_results_ibfk_3` | `evaluation_results.eva_question_id` | `evaluation_questions.eva_question_id` | CASCADE |
| `exam_answers_ibfk_1` | `exam_answers.user_id` | `users.id` | CASCADE |
| `exam_answers_ibfk_2` | `exam_answers.q_id` | `stock_question.id` | CASCADE |
| `exam_answers_ibfk_3` | `exam_answers.open_ex_id` | `open_exam.id` | SET NULL |
| `open_exam_ibfk_1` | `open_exam.st_plan_id` | `study_plan.id` | SET NULL |
| `permission_roles_ibfk_1` | `permission_roles.permission_id` | `permissions.id` | CASCADE |
| `permission_roles_ibfk_2` | `permission_roles.role_id` | `roles.id` | CASCADE |
| `room_booking_ibfk_1` | `room_booking.room_id` | `rooms.id` | CASCADE |
| `room_booking_ibfk_2` | `room_booking.user_id` | `users.id` | CASCADE |
| `std_family_ibfk_1` | `std_family.std_id` | `students.id` | CASCADE |
| `std_family_ibfk_2` | `std_family.village_id` | `villages.id` | SET NULL |
| `stock_answers_ibfk_1` | `stock_answers.q_id` | `stock_question.id` | CASCADE |
| `stock_question_ibfk_1` | `stock_question.sub_id` | `subjects.id` | SET NULL |
| `stock_question_ibfk_2` | `stock_question.onwer` | `users.id` | SET NULL |
| `student_groups_ibfk_1` | `student_groups.curriculum_id` | `curriculums.id` | CASCADE |
| `students_ibfk_1` | `students.std_type_id` | `student_type.id` | CASCADE |
| `students_ibfk_2` | `students.std_group_id` | `student_groups.id` | SET NULL |
| `students_ibfk_3` | `students.curri_id` | `curriculums.id` | CASCADE |
| `study_plan_ibfk_1` | `study_plan.semaster_id` | `semaster.id` | CASCADE |
| `study_plan_ibfk_2` | `study_plan.subject_id` | `subjects.id` | CASCADE |
| `study_plan_ibfk_3` | `study_plan.std_group_id` | `student_groups.id` | CASCADE |
| `study_plan_ibfk_4` | `study_plan.teacher_id` | `teachers.id` | CASCADE |
| `study_plan_ibfk_5` | `study_plan.room_id` | `rooms.id` | SET NULL |
| `subjects_ibfk_1` | `subjects.curri_id` | `curriculums.id` | CASCADE |
| `subjects_ibfk_2` | `subjects.group_id` | `subject_group.id` | CASCADE |
| `teachers_ibfk_1` | `teachers.dept_id` | `departments.id` | CASCADE |
| `teachers_ibfk_2` | `teachers.division_id` | `divisions.id` | SET NULL |
| `user_devices_ibfk_1` | `user_devices.user_id` | `users.id` | CASCADE |
| `user_noti_ibfk_1` | `user_noti.user_id` | `users.id` | CASCADE |
| `user_noti_ibfk_2` | `user_noti.noti_id` | `notifications.noti_id` | CASCADE |
| `user_roles_ibfk_1` | `user_roles.role_id` | `roles.id` | CASCADE |
| `user_roles_ibfk_2` | `user_roles.user_id` | `users.id` | CASCADE |
| `villages_ibfk_1` | `villages.district_id` | `districts.id` | CASCADE |

---

## AUTO_INCREMENT Status

Current next-ID values as of the dump date:

| Table | PK Column | Next ID |
|-------|-----------|---------|
| `curriculums` | `id` | 11 |
| `departments` | `id` | 11 |
| `districts` | `id` | 11 |
| `divisions` | `id` | 11 |
| `enrollments` | `id` | 21 |
| `evaluation_questions` | `eva_question_id` | 16 |
| `evaluation_results` | `eva_results_id` | 12 |
| `exam_answers` | `id` | 11 |
| `major` | `id` | 11 |
| `notifications` | `noti_id` | 24 |
| `open_exam` | `id` | 11 |
| `permissions` | `id` | 11 |
| `permission_roles` | `id` | 11 |
| `provinces` | `id` | 12 |
| `roles` | `id` | 11 |
| `rooms` | `id` | 21 |
| `room_booking` | `booking_id` | 14 |
| `semaster` | `id` | 11 |
| `std_family` | `id` | 21 |
| `stock_answers` | `id` | 11 |
| `stock_question` | `id` | 11 |
| `students` | `id` | 21 |
| `student_groups` | `id` | 21 |
| `student_type` | `id` | 11 |
| `study_plan` | `id` | 21 |
| `subjects` | `id` | 40 |
| `subject_group` | `id` | 11 |
| `teachers` | `id` | 21 |
| `users` | `id` | 23 |
| `user_devices` | `id` | 16 |
| `user_noti` | `id` | 21 |
| `user_roles` | `id` | 21 |
| `villages` | `id` | 11 |

---

*End of schema document. Generated from `ceit_db__3_.sql` · MariaDB 10.4.32 · May 2026.*
