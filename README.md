# 🔔 Daily Quote Notifications — Status Report (QuoteVault)

This document explains the implementation status of the **Daily Quote & Notifications** feature in the **QuoteVault** app.

---

## 📌 Feature Requirement (From Assignment)

### 4. Daily Quote & Notifications (10 marks)
- [x] "Quote of the Day" prominently displayed on home screen  
- [x] Quote of the day changes daily (server-side or local logic)  
- [ ] Local push notification for daily quote  
- [ ] User can set preferred notification time in settings  

---

## ✅ Implemented in This Submission

### ✅ Quote of the Day (QOTD)
The app includes a **Quote of the Day** feature:

- Displayed prominently on the Home screen
- Quote updates daily using **local date-based logic**
- Same quote remains stable throughout the day
- Works offline (since it does not depend on notifications)

---

## ❌ Not Implemented in This Submission

### ❌ Local Push Notifications
The following items are **not implemented** in this submission:

- Daily local push notification for Quote of the Day  
- User preference screen to set notification time  
- Scheduling notifications with timezone support  
- Notification permission handling (Android/iOS)  
- Background scheduling and rescheduling logic  

---

## 🧾 Reason for Incompletion

This submission prioritised the core functional areas:

- Supabase Authentication
- Quote browsing (feed, categories, search, author filtering)
- Favorites & Collections with cloud sync
- Quote card sharing/export
- Settings and personalization

Due to time constraints, **local notifications were not completed** before the deadline.

---

## 🛠️ Future Scope / Planned Implementation

If the project timeline is extended, notifications will be added with the following plan:

---

### 🔧 Packages (Flutter)
Planned packages for implementation:

- `flutter_local_notifications`
- `timezone`

---

### 🎯 Planned Notification Features
- Daily notification with Quote of the Day
- Notification includes:
  - Quote text
  - Author name
- User can configure:
  - Enable / disable notifications
  - Preferred notification time (e.g., 8:00 AM)
- Notification preferences will be stored:
  - Locally for instant usage
  - In Supabase user profile for cross-device sync

---

## 🧩 Proposed Implementation Steps (High-Level)

1. **Request Notification Permission**
   - Android: runtime permission (Android 13+)
   - iOS: request alert/sound/badge permission

2. **Initialize Notification Plugin**
   - Setup Android notification channel
   - Setup iOS notification settings

3. **Timezone Setup**
   - Initialize timezone database
   - Detect device timezone
   - Ensure scheduled time triggers correctly

4. **Schedule Daily Quote Notification**
   - Schedule once per day at preferred time
   - Use Quote of the Day as notification payload

5. **Settings Integration**
   - Add TimePicker for preferred time
   - Save time preference locally + Supabase

6. **Reschedule on Changes**
   - If user updates time → cancel old schedule → create new schedule

7. **Optional Enhancements**
   - Deep link into the app when notification is tapped
   - Open directly to the Quote of the Day screen

---

## 📌 Notes for Reviewer

Even without notifications, the app successfully delivers the expected quote experience:

- Complete authentication flow (Supabase)
- Quote feed + categories + search + filter
- Favorites + collections with cloud sync
- Share/export quote cards
- Polished UI and personalization options
- Offline-friendly browsing experience (graceful handling)

---

✅ Thank you for reviewing **QuoteVault** 🚀
