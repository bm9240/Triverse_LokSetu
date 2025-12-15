# Trust & Reputation System - Implementation Guide

## 🎯 Overview
The Trust & Reputation System for LokSetu provides risk signals for complaint validation while maintaining inclusivity. **Complaints are NEVER rejected** based on trust score - the system only provides metadata to support decision-making.

---

## 📊 System Components

### 1. **Citizen Trust Score** (Per Complaint, Internal)
- **Purpose**: Calculate risk probability based on complaint patterns
- **Visibility**: Internal only - NOT shown to citizens as numeric value
- **Range**: 0-100 (internal calculation)
- **Status Mapping**:
  - `HIGH` (70-100): High confidence
  - `MEDIUM` (40-69): Additional clarification may help
  - `LOW` (0-39): Sent for verification

### 2. **Trust Calculation Factors**
Located in: `lib/services/trust_service.dart`

#### Factor Weights:
1. **Photo-Text Match** (35%) - MOST IMPORTANT
   - Clear semantic match → increase trust
   - Ambiguous text → neutral
   - Clear mismatch → significant trust reduction (risk signal)

2. **Historical Behavior** (20%)
   - Pattern-based over time
   - Single mistakes are OK
   - Repeated issues reduce trust gradually

3. **Input Consistency** (20%)
   - Category matches description keywords
   - Duration aligns with severity
   - Logical complaint structure

4. **Evidence Presence** (15%)
   - Photo/video provided → increase trust
   - Text-only → neutral (NO penalty for low literacy)

5. **Severity Misuse** (10%)
   - Repeated use of High/Critical severity → reduce trust

#### What is NOT Used (Inclusivity Principle):
- ❌ Language quality or grammar
- ❌ English vs Hindi/Hinglish
- ❌ Typing skills
- ❌ Device or camera quality

---

## 👥 Citizen-Facing Trust Display

### When Visible
- Only shown ONCE: when an official is assigned to the complaint
- Never shown during complaint submission

### What Citizens See
**Soft labels only** (not numeric scores):
- `HIGH` → "High confidence"
- `MEDIUM` → "Additional clarification may help"
- `LOW` → "Sent for verification"

### What Citizens NEVER See
- ❌ Numeric trust score
- ❌ Words like "suspicious", "fake", "unreliable", "low trust"
- ❌ Rejection or blocking messages

Location: `lib/screens/complaint_detail_screen.dart`  
Method: `_buildTrustStatusBanner()`

---

## ✅ Official-Initiated Validation

### Rules
1. **Only for LOW trust complaints**
2. **Official must manually trigger** validation (not automatic)
3. **Simple Yes/No confirmation** from citizen (no text input required)
4. **Non-blocking**: Complaint continues regardless of response

### Workflow
1. Admin sees trust status in complaint card
2. If `trustStatus == LOW`, admin can click "Request Validation"
3. Citizen receives simple confirmation request
4. Response adjusts trust:
   - Confirmed → partial trust restoration (+20 points)
   - No response → trust remains low
   - Repeated non-response → maintains low status

Location: `lib/screens/admin_screen.dart`  
Method: `_requestValidation()`

---

## 😊 Citizen Feedback (After Resolution)

### When Shown
- Only after complaint status = `COMPLETED`
- One-time prompt, no repeat

### Feedback Options (Emoji Only)
- 😊 **Positive** - Satisfied
- 😐 **Neutral** - Partially resolved
- 😞 **Negative** - Not resolved

### Impact
- Feeds into official reputation score
- No text feedback required (low-literacy friendly)

Location: `lib/screens/complaint_detail_screen.dart`  
Method: `_buildEmojiFeedbackSection()`

---

## 🏛️ Official Reputation Score

### Purpose
Admin-only accountability metric

### Calculation Factors
1. **Citizen Feedback** (40% weight) - MOST IMPORTANT
   - Positive: 1.0
   - Neutral: 0.5
   - Negative: 0.0

2. **Resolution Rate** (30%)
   - Resolved / Total complaints

3. **Response Time** (15%)
   - Target: ≤24 hours
   - Penalty: >72 hours

4. **Reopen Rate** (15%)
   - Reopened / Resolved complaints

### Reputation Tiers
- **Excellent**: 80-100
- **Good**: 60-79
- **Average**: 40-59
- **Needs Improvement**: 0-39

### Visibility
- **Admin only** - NOT shown to citizens
- Used for internal monitoring and accountability

Location: `lib/services/reputation_service.dart`  
Class: `OfficialReputation`

---

## 📁 File Structure

```
lib/
├── models/
│   ├── trust_score.dart              # Trust status, factors, validation request
│   ├── citizen_feedback.dart         # Emoji feedback enum
│   └── official_reputation.dart      # Official performance tracking
├── services/
│   ├── trust_service.dart            # Trust calculation logic
│   └── reputation_service.dart       # Reputation tracking
└── screens/
    ├── complaint_detail_screen.dart  # Trust banner + emoji feedback UI
    └── admin_screen.dart             # Trust display + validation trigger
```

---

## 🔗 Integration with Existing System

### Complaint Model Changes
Added optional fields to `lib/models/complaint.dart`:
```dart
int? trustScore;                      // Internal (0-100)
TrustStatus? trustStatus;             // HIGH/MEDIUM/LOW
CitizenFeedback? citizenFeedback;     // Emoji after resolution
ValidationRequest? validationRequest; // Official-initiated only
```

### Provider Integration
No changes to `ComplaintProvider` - uses existing `updateComplaint()` method

### ProofChain Integration
No changes - trust system is metadata only

### AutoGov Engine Integration
No changes - trust system doesn't affect routing or assignment

---

## 🚀 Usage Workflow

### For Citizens
1. Submit complaint (no trust check)
2. Once official assigned → see trust status (soft label)
3. If LOW trust → may receive validation request (respond Yes/No)
4. After resolution → provide emoji feedback

### For Officials (Admin)
1. View complaint list with trust indicators
2. For LOW trust → optionally request validation
3. Add proof and update status normally
4. Reputation score updated automatically

### For Admin (Monitoring)
1. View official reputation scores (admin panel)
2. Monitor performance metrics
3. Use for accountability, not public ranking

---

## ⚠️ Critical Design Principles

1. **Never Reject Complaints**
   - Trust is a risk signal, not a blocker

2. **Gradual Trust Changes**
   - Single mistakes don't cause large drops
   - Patterns over time matter more

3. **Inclusive Design**
   - No penalties for low literacy
   - Emoji-based feedback
   - Simple Yes/No validation

4. **Privacy & Transparency**
   - Soft labels for citizens
   - Numeric scores for internal use only
   - Clear communication

5. **Pattern-Based, Not Predictive**
   - Historical behavior matters
   - Inconsistency is a risk signal, not proof
   - Community patterns (optional future enhancement)

---

## 🧪 Testing Guide

### Test Scenarios

#### 1. High Trust Complaint
- Photo matches description
- Consistent category/location/duration
- Clear evidence

**Expected**: Trust score 70-100, status = HIGH

#### 2. Medium Trust Complaint
- Text-only complaint
- Reasonable description
- No red flags

**Expected**: Trust score 40-69, status = MEDIUM

#### 3. Low Trust Complaint
- Photo-text mismatch
- Inconsistent details
- Repeated high severity misuse

**Expected**: Trust score 0-39, status = LOW

#### 4. Validation Flow
- Admin triggers validation for LOW trust
- Citizen confirms → trust increases
- Citizen ignores → trust stays low

#### 5. Feedback Flow
- Complaint resolved
- Citizen provides emoji feedback
- Official reputation updated

---

## 🔧 Future Enhancements (Not Implemented)

1. **Community Corroboration**
   - Multiple complaints from same area → auto-boost trust
   - Currently not used per requirements

2. **ML-Based Photo-Text Matching**
   - Currently uses heuristics
   - Could integrate ML for better accuracy

3. **Real-time Notifications**
   - Push notifications for validation requests
   - Currently in-app only

4. **Analytics Dashboard**
   - Trust score trends over time
   - Official performance comparison

---

## 📞 Support & Maintenance

### Monitoring Points
- Trust score distribution
- Validation response rates
- Official reputation trends
- Feedback submission rates

### Key Metrics
- % of LOW trust complaints
- Validation request rate
- Citizen feedback rate
- Official avg reputation

---

## ✅ Compliance Checklist

- [x] Trust score never rejects complaints
- [x] Soft labels for citizens (not numeric)
- [x] Validation only for LOW trust
- [x] Official must trigger validation
- [x] Emoji-only feedback
- [x] Official reputation admin-only
- [x] No penalties for literacy/language
- [x] Pattern-based trust calculation
- [x] ProofChain/AutoGov not modified
- [x] Minimal changes to existing code

---

**Implementation Complete** ✅  
System is ready for deployment with full inclusivity and privacy compliance.
