# Server-Side API: What to UPDATE vs CREATE

Use this list on the server. **UPDATE** = change an existing endpoint. **CREATE** = add a new endpoint.

---

## UPDATE (2 existing APIs)

### 1. UPDATE: POST `/api/appliedjob`

**Already exists.** Ensure it does the following:

- **Accepts** (in request body):
  - `jobId` (number)
  - `candidateId` (number)
  - **`referenceId`** (string) – **add if missing** (app sends e.g. `"DCT-1737812345-1234"`)
  - `goodFitAnswer`, `startDate`, `shareProfile`
  - **`skillTestScore`**, **`skillTestPassed`**, **`skillTestTimeUsed`**
  - **`skillTestAnswers`** (array of `{ questionId, selectedOptionIndex }`)
  - **`totalQuestions`**, **`correctAnswers`**, **`attemptedQuestions`**

- **Response** (200/201):  
  `{ "success": true, "message": "...", "data": { "id", "jobId", "candidateId", "status", "createdAt" } }`

---

### 2. UPDATE: POST `/api/fetchjob`

**Already exists.** Add per-job fields for the **logged-in candidate**:

- **Add to each job** in `data` array:
  - **`applied`** (boolean) – `true` if this candidate has applied
  - **`applicationStatus`** (string) – e.g. `"applied"` or `"not_applied"`

App uses these for “Applied” badge and disabling apply.

---

## CREATE (6 new APIs)

All new endpoints: **POST**, **Auth:** `Authorization: Bearer <token>`, **Content-Type:** `application/json`.

---

### 3. CREATE: POST `/api/appliedjob/fetch_employer_overview`

**New endpoint.** Returns dashboard numbers for the employer.

- **Request body:** `{}`
- **Response (200):**
```json
{
  "success": true,
  "message": "Overview fetched successfully",
  "data": {
    "openRoles": 6,
    "activeCandidates": 48,
    "interviewsToday": 3,
    "pendingReviews": 9
  }
}
```
- **Logic:** From `appliedjob` (and jobs) for this employer: count open roles, total candidates, interviews today, pending/applied.

---

### 4. CREATE: POST `/api/appliedjob/fetch_employer_applications`

**New endpoint.** Returns employer’s jobs with candidate counts.

- **Request body:** `{}`
- **Response (200):**
```json
{
  "success": true,
  "message": "Applications fetched successfully",
  "data": [
    {
      "jobId": 6,
      "id": 6,
      "jobTitle": "Data Center Technician",
      "companyName": "EdgeCore Systems",
      "location": "Seattle, WA",
      "workType": "Full-time",
      "locationType": "On-site",
      "minPay": 38000.00,
      "maxPay": 45000.00,
      "salaryType": "hr",
      "totalCandidates": 12,
      "inScreening": 4,
      "interviews": 2,
      "applied": 6,
      "status": "active",
      "createdAt": "2026-01-25T06:20:29.391734Z",
      "updatedAt": null
    }
  ]
}
```
- **Logic:** For each job: job fields + counts by stage (total, inScreening, interviews, applied). Optional: `status` (`"active"` / `"closed"` / `"draft"`) for tabs.

---

### 5. CREATE: POST `/api/appliedjob/fetch_candidates_by_job`

**New endpoint.** Returns candidates for one job (pipeline).

- **Request body:** `{ "jobId": 6 }`
- **Response (200):**
```json
{
  "success": true,
  "message": "Candidates fetched successfully",
  "data": [
    {
      "id": 1,
      "applicationId": 1,
      "jobId": 6,
      "candidateId": 12,
      "candidate": {
        "id": 12,
        "fullName": "Alex Johnson",
        "fullname": "Alex Johnson",
        "location": "Seattle, WA",
        "experienced": "4",
        "experience": "4"
      },
      "stage": "Initial screening",
      "applicationStatus": "screening",
      "skillTestScore": 92.5,
      "matchPercent": "94%",
      "matchPercentage": "94%",
      "startDate": "2026-02-01",
      "createdAt": "2026-01-25T10:30:00Z"
    }
  ]
}
```
- **Logic:** Filter by `jobId`, join candidate table, return application + nested `candidate`.

---

### 6. CREATE: POST `/api/appliedjob/fetch_candidate_details`

**New endpoint.** Returns one candidate/application details (for candidate details screen).

- **Request body:** `{ "applicationId": 1, "candidateId": 12 }`
- **Response (200):**
```json
{
  "success": true,
  "message": "Candidate details fetched successfully",
  "data": {
    "application": {
      "id": 1,
      "jobId": 6,
      "candidateId": 12,
      "stage": "In screening",
      "skillTestScore": 92.5,
      "matchPercent": "94%",
      "startDate": "2026-02-01",
      "createdAt": "2026-01-25T10:30:00Z",
      "updatedAt": "2026-01-25T12:00:00Z"
    },
    "candidate": {
      "id": 12,
      "fullName": "Alex Johnson",
      "fullname": "Alex Johnson",
      "location": "Seattle, WA",
      "experienced": "4",
      "experience": "4",
      "headline": "Data Center Technician • L3 operations",
      "bio": "...",
      "experienceSummary": "4 years • EdgeCore Systems",
      "currentCompany": "EdgeCore Systems",
      "skills": ["Rack & stack", "Troubleshooting"],
      "coreSkills": "Rack & stack • Troubleshooting",
      "cvPath": "/uploads/cv/xxx.pdf",
      "cvFileName": "Alex_Johnson_Resume.pdf",
      "cvUpdatedDate": "2026-01-20T10:00:00Z",
      "workType": "Full-time",
      "locationType": "On-site"
    },
    "activity": [
      { "title": "Moved to screening", "createdAt": "2026-01-25T11:00:00Z" },
      { "title": "Application received", "createdAt": "2026-01-25T10:30:00Z" }
    ]
  }
}
```
- **Logic:** Load application by `applicationId` (or `candidateId` + job), load candidate, optionally build `activity` from application history.  
- **Note:** `candidate` fields like `headline`, `skills`, `cvPath`, `activity` are optional; app has fallbacks.

---

### 7. CREATE: POST `/api/appliedjob/update_candidate_stage`

**New endpoint.** Updates pipeline stage for an application.

- **Request body:** `{ "applicationId": 1, "stage": "initial screening" }`  
  (App sends `stage` in lowercase.)
- **Response (200):**
```json
{
  "success": true,
  "message": "Stage updated successfully",
  "data": {
    "id": 1,
    "stage": "initial screening",
    "updatedAt": "2026-01-25T12:00:00Z"
  }
}
```
- **Logic:** Update `stage` (and `updatedAt`) in `appliedjob` for given `applicationId`.

---

### 8. CREATE: POST `/api/appliedjob/schedule_interview`

**New endpoint.** Used when employer confirms “Move to interview” with optional interview details. Updates stage to “technical interview” and optionally saves interview schedule.

- **Request body:**
```json
{
  "applicationId": 1,
  "candidateId": 12,
  "stage": "technical interview",
  "interviewType": "video",
  "scheduledDate": "2026-02-15",
  "scheduledTime": "14:30",
  "interviewer": "Jane Smith",
  "internalNote": "Focus on troubleshooting experience."
}
```
- All fields except `applicationId` and `stage` are **optional**. App sends only filled-in fields.
- **`interviewType`** – one of `"phone"`, `"video"`, `"onsite"` (app sends lowercase).
- **`scheduledDate`** – `YYYY-MM-DD`.
- **`scheduledTime`** – `HH:mm` (24h).

- **Response (200):**
```json
{
  "success": true,
  "message": "Interview scheduled successfully",
  "data": {
    "applicationId": 1,
    "stage": "technical interview",
    "updatedAt": "2026-01-25T12:00:00Z",
    "interview": {
      "id": 1,
      "applicationId": 1,
      "interviewType": "video",
      "scheduledDate": "2026-02-15",
      "scheduledTime": "14:30",
      "interviewer": "Jane Smith",
      "internalNote": "Focus on troubleshooting experience.",
      "createdAt": "2026-01-25T12:00:00Z"
    }
  }
}
```
- **Logic:**
  1. Update `appliedjob.stage` to `"technical interview"` (or `"interview"`) for given `applicationId`.
  2. If `interviewType`, `scheduledDate`, `scheduledTime`, `interviewer`, or `internalNote` are present, create/update an **interview** record linked to this application (e.g. table `interview` with `applicationId`, `interviewType`, `scheduledDate`, `scheduledTime`, `interviewer`, `internalNote`).
  3. Return success and optionally the updated application + interview.

**Note:** “Skip scheduling for now” uses existing **POST `/api/appliedjob/update_candidate_stage`** with `{ "applicationId", "stage": "technical interview" }` only; no schedule_interview call.

---

## Summary table

| # | Endpoint | Action | Notes |
|---|----------|--------|--------|
| 1 | POST `/api/appliedjob` | **UPDATE** | Add `referenceId`, skill test fields; keep response shape |
| 2 | POST `/api/fetchjob` | **UPDATE** | Add `applied`, `applicationStatus` per job for logged-in candidate |
| 3 | POST `/api/appliedjob/fetch_employer_overview` | **CREATE** | New; returns 4 counts |
| 4 | POST `/api/appliedjob/fetch_employer_applications` | **CREATE** | New; jobs + candidate counts |
| 5 | POST `/api/appliedjob/fetch_candidates_by_job` | **CREATE** | New; body `{ "jobId" }` |
| 6 | POST `/api/appliedjob/fetch_candidate_details` | **CREATE** | New; body `{ "applicationId", "candidateId" }` |
| 7 | POST `/api/appliedjob/update_candidate_stage` | **CREATE** | New; body `{ "applicationId", "stage" }` |
| 8 | POST `/api/appliedjob/schedule_interview` | **CREATE** | New; body `{ "applicationId", "stage", "interviewType?", "scheduledDate?", "scheduledTime?", "interviewer?", "internalNote?" }` – move to interview + optional schedule |

No other new endpoints are required. All use **Bearer token** in header.
