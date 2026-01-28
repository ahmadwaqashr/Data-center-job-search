# Server-Side API Spec (Employer & Application Flow)

The app expects these endpoints and shapes. Implement or update on the server as needed.

---

## 1. Candidate: Apply for job (already in use)

**POST** `/api/appliedjob`

**Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

**Request body:**
```json
{
  "jobId": 6,
  "candidateId": 12,
  "referenceId": "DCT-1737812345-1234",
  "goodFitAnswer": "...",
  "startDate": "2026-02-01",
  "shareProfile": true,
  "skillTestScore": 92.5,
  "skillTestPassed": true,
  "skillTestTimeUsed": 300,
  "skillTestAnswers": [
    { "questionId": 1, "selectedOptionIndex": 2 },
    { "questionId": 2, "selectedOptionIndex": 0 }
  ],
  "totalQuestions": 10,
  "correctAnswers": 9,
  "attemptedQuestions": 10
}
```

**Response (200/201):**
```json
{
  "success": true,
  "message": "Application submitted successfully",
  "data": {
    "id": 1,
    "jobId": 6,
    "candidateId": 12,
    "status": "pending",
    "createdAt": "2026-01-25T10:30:00Z"
  }
}
```

---

## 2. Candidate: Fetch jobs (with applied status)

**POST** `/api/fetchjob`

**Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

**Request body (optional):**
```json
{
  "search": "optional search text"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Jobs fetched successfully",
  "data": [
    {
      "id": 8,
      "employerId": 17,
      "jobTitle": "Data Center Technician",
      "companyName": "EdgeCore Systems",
      "location": "Seattle, WA",
      "workType": "Full-time",
      "locationType": "On-site",
      "seniority": "Mid-level",
      "salaryType": "hr",
      "minPay": 40.00,
      "maxPay": 50.00,
      "jobDescription": "...",
      "requirements": "...",
      "skills": ["Rack & stack", "Fiber & cabling"],
      "shifts": ["Night shifts"],
      "banefit": ["dinner", "lunch"],
      "coreExpertiseId": 2,
      "passingScore": 80,
      "selectedQuestionIds": [6, 7, 8, 9],
      "logoPath": "/uploads/logos/...",
      "createdAt": "2026-01-25T10:59:54.539327Z",
      "updatedAt": null,
      "applied": true,
      "applicationStatus": "applied"
    }
  ]
}
```

**Required for “Applied” UI:** Each job object must include either:
- `applied`: boolean, and/or  
- `applicationStatus`: string (e.g. `"applied"` or `"not_applied"`).

---

## 3. Employer: Overview stats

**POST** `/api/appliedjob/fetch_employer_overview`

**Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

**Request body:** `{}`

**Response (200):**
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

**Alternative field names (app supports both):**  
`openRolesCount`, `activeCandidatesCount`, `interviewsTodayCount`, `pendingReviewsCount`.

---

## 4. Employer: Jobs with candidate counts (Home + Jobs screen)

**POST** `/api/appliedjob/fetch_employer_applications`

**Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

**Request body:** `{}`

**Response (200):**
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
      "updatedAt": null,
      "referenceId": "DCT-2841-5234"
    }
  ]
}
```

**Required fields per job:**
- `jobId` or `id` (used for pipeline and navigation).
- `jobTitle`, `companyName`, `location`, `locationType`, `workType`, `minPay`, `maxPay`, `salaryType`.
- `totalCandidates` (or `totalCandidatesCount`).
- `inScreening` (or `inScreeningCount`), `interviews` (or `interviewsCount`).
- `createdAt`, `updatedAt` (optional but used for “Posted X ago” / “Closed X”).

**Optional for Open/Closed/Draft tabs (Employer Jobs screen):**
- `status`: `"active"` / `"open"` → Open; `"closed"` / `"archived"` / `"filled"` → Closed; `"draft"` → Draft.  
  If you don’t send `status`, all jobs are shown under Open.

---

## 5. Employer: Candidates by job (Pipeline)

**POST** `/api/appliedjob/fetch_candidates_by_job`

**Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

**Request body:**
```json
{
  "jobId": 6
}
```

**Response (200):**
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

**Stage values (app logic):**
- **Applied:** `stage`/`applicationStatus` contains `pending` or `applied` (or empty).
- **In screening:** contains `screening` or `initial`.
- **Interviews:** contains `interview`, `technical`, `offer`, or `onboarding`.

Use consistent casing (e.g. `"Initial screening"`, `"Technical interview"`, `"Offer & onboarding"`); app normalizes with `.toLowerCase()` for filtering.

---

## 6. Employer: Candidate details

**POST** `/api/appliedjob/fetch_candidate_details`

**Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

**Request body:**
```json
{
  "applicationId": 1,
  "candidateId": 12
}
```

**Response (200):**
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
      "matchPercent": "94%"
    },
    "candidate": {
      "id": 12,
      "fullName": "Alex Johnson",
      "location": "Seattle, WA",
      "experienced": "4"
    }
  }
}
```

---

## 7. Employer: Update candidate stage

**POST** `/api/appliedjob/update_candidate_stage`

**Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

**Request body:**
```json
{
  "applicationId": 1,
  "stage": "initial screening"
}
```

**Note:** App sends `stage` in lowercase (e.g. `"pending"`, `"initial screening"`, `"technical interview"`, `"offer & onboarding"`). Server can store in any format; UI displays with first letter capitalized.

**Response (200):**
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

---

## Summary: What to implement/update

| Endpoint | Action |
|----------|--------|
| `POST /api/appliedjob` | Already used; ensure it accepts `referenceId` and full payload above. |
| `POST /api/fetchjob` | Ensure each job includes `applied` and/or `applicationStatus` for the logged-in candidate. |
| `POST /api/appliedjob/fetch_employer_overview` | Return `openRoles`, `activeCandidates`, `interviewsToday`, `pendingReviews` (or *Count variants). |
| `POST /api/appliedjob/fetch_employer_applications` | Return list of jobs with `jobId`/`id`, candidate counts, and optional `status` for Open/Closed/Draft. |
| `POST /api/appliedjob/fetch_candidates_by_job` | Accept `jobId`; return list of applications with `candidate`, `stage`/`applicationStatus`, scores. |
| `POST /api/appliedjob/fetch_candidate_details` | Accept `applicationId` + `candidateId`; return `application` + `candidate` objects. |
| `POST /api/appliedjob/update_candidate_stage` | Accept `applicationId` + `stage`; update and return success. |

No new endpoints are required; only ensure request/response shapes and field names match above so the app can parse and display data correctly.
