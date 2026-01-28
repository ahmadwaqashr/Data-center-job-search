# API Implementation Checklist for Server Side

## ✅ APIs Already Working (May Need Updates)

### 1. **POST `/api/appliedjob`** - Apply for Job
**Status:** ✅ Already exists  
**Action:** ⚠️ **UPDATE** - Ensure it accepts these fields:
- `referenceId` (string) - **NEW FIELD** - App generates this client-side
- `skillTestAnswers` (array) - Array of `{questionId, selectedOptionIndex}`
- `skillTestScore`, `skillTestPassed`, `skillTestTimeUsed`
- `totalQuestions`, `correctAnswers`, `attemptedQuestions`
- `goodFitAnswer`, `startDate`, `shareProfile`

**Response must include:**
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

### 2. **POST `/api/fetchjob`** - Fetch Jobs (Candidate)
**Status:** ✅ Already exists  
**Action:** ⚠️ **UPDATE** - Add these fields to each job in response:
- `applied` (boolean) - **NEW FIELD** - `true` if logged-in candidate applied
- `applicationStatus` (string) - **NEW FIELD** - `"applied"` or `"not_applied"`

**Why:** App needs this to show "Applied" badge and disable apply buttons.

---

## 🆕 APIs That Need to Be CREATED

### 3. **POST `/api/appliedjob/fetch_employer_overview`** - Employer Overview Stats
**Status:** 🆕 **CREATE NEW**  
**Purpose:** Get dashboard stats for employer home screen

**Request:**
```json
{}
```

**Response:**
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

**Logic needed:**
- `openRoles`: Count of active/open jobs for this employer
- `activeCandidates`: Total candidates in pipeline (all stages)
- `interviewsToday`: Candidates with stage containing "interview" and scheduled for today
- `pendingReviews`: Candidates in "pending" or "applied" stage

---

### 4. **POST `/api/appliedjob/fetch_employer_applications`** - Employer Jobs List
**Status:** 🆕 **CREATE NEW**  
**Purpose:** Get all jobs posted by employer with candidate counts

**Request:**
```json
{}
```

**Response:**
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

**Required fields:**
- Job details: `jobId`/`id`, `jobTitle`, `companyName`, `location`, `workType`, `locationType`, `minPay`, `maxPay`, `salaryType`
- Candidate counts: `totalCandidates`, `inScreening`, `interviews`, `applied`
- Optional: `status` (`"active"`, `"closed"`, `"draft"`) for Open/Closed/Draft tabs

**Logic needed:**
- Group applications by `jobId`
- Count candidates by stage:
  - `totalCandidates`: All applications for this job
  - `inScreening`: Stage contains "screening" or "initial"
  - `interviews`: Stage contains "interview", "technical", "offer", or "onboarding"
  - `applied`: Stage is "pending" or "applied" or empty

---

### 5. **POST `/api/appliedjob/fetch_candidates_by_job`** - Pipeline Candidates
**Status:** 🆕 **CREATE NEW**  
**Purpose:** Get all candidates for a specific job (pipeline screen)

**Request:**
```json
{
  "jobId": 6
}
```

**Response:**
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

**Required fields:**
- Application: `id`/`applicationId`, `jobId`, `candidateId`, `stage`/`applicationStatus`, `skillTestScore`, `matchPercent`, `startDate`, `createdAt`
- Candidate nested object: `id`, `fullName`/`fullname`, `location`, `experienced`/`experience`

**Logic needed:**
- Filter applications by `jobId`
- Join with candidate table to get candidate details
- Include `stage` from application (or `applicationStatus` as fallback)

---

### 6. **POST `/api/appliedjob/fetch_candidate_details`** - Candidate Details
**Status:** 🆕 **CREATE NEW**  
**Purpose:** Get full details of a specific candidate/application

**Request:**
```json
{
  "applicationId": 1,
  "candidateId": 12
}
```

**Response:**
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

**Logic needed:**
- Fetch application by `applicationId` (or `candidateId` + `jobId` if `applicationId` not provided)
- Fetch candidate details by `candidateId`
- Return both as nested objects

---

### 7. **POST `/api/appliedjob/update_candidate_stage`** - Update Stage
**Status:** 🆕 **CREATE NEW**  
**Purpose:** Update candidate's pipeline stage

**Request:**
```json
{
  "applicationId": 1,
  "stage": "initial screening"
}
```

**Note:** App sends `stage` in lowercase. Server can normalize/store in any format.

**Response:**
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

**Logic needed:**
- Update `stage` field in `appliedjob` table for given `applicationId`
- Return updated application record

---

## 📋 Summary Table

| Endpoint | Status | Action | Priority |
|----------|--------|--------|----------|
| `POST /api/appliedjob` | ✅ Exists | ⚠️ **UPDATE** - Add `referenceId` and skill test fields | High |
| `POST /api/fetchjob` | ✅ Exists | ⚠️ **UPDATE** - Add `applied` and `applicationStatus` fields | High |
| `POST /api/appliedjob/fetch_employer_overview` | 🆕 New | ✅ **CREATE** | High |
| `POST /api/appliedjob/fetch_employer_applications` | 🆕 New | ✅ **CREATE** | High |
| `POST /api/appliedjob/fetch_candidates_by_job` | 🆕 New | ✅ **CREATE** | High |
| `POST /api/appliedjob/fetch_candidate_details` | 🆕 New | ✅ **CREATE** | High |
| `POST /api/appliedjob/update_candidate_stage` | 🆕 New | ✅ **CREATE** | High |

---

## 🔑 Key Points

1. **All endpoints require:** `Authorization: Bearer <token>` header
2. **All responses must have:** `{ "success": true/false, "message": "...", "data": ... }` format
3. **Stage values:** App accepts any casing; it normalizes to lowercase for filtering
4. **ID fields:** Can be `int` or `num`; app handles both
5. **Optional fields:** App has fallbacks, but include as many fields as possible for best UX

---

## 📝 Database Table Reference

All new APIs work with the **`appliedjob`** table (or equivalent). Expected fields:
- `id` (application ID)
- `jobId`
- `candidateId`
- `stage` or `applicationStatus`
- `skillTestScore`
- `matchPercent`
- `startDate`
- `referenceId` (from application submission)
- `createdAt`, `updatedAt`

Join with:
- `jobposted` table (for job details)
- `candidate`/`user` table (for candidate details)
