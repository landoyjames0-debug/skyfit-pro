# SkyFit Pro OTP Fix Task

## Steps to Complete:

### 1. [x] Update AuthViewModel.registerWithEmail ✅

- Modified to auto signIn after createUser
- Ensures returns true on success, notifies listeners

### 2. [x] Simplify RegisterView onVerified callback ✅

- Removed popUntil, registered modal, photo upload from callback
- Now just calls authVM.registerWithEmail → userVM.createProfile
- OTP view handles navigation to HomeView

### 3. [ ] Test registration flow

- Register new user → enter OTP → verify → auto sign-in → HomeView

### 4. [ ] Verify Firebase

- Check user created and signed in
- Profile saved to Firestore

**Progress: 2/4**

### 3. [ ] Test registration flow

- Register new user → enter OTP → verify → auto sign-in → HomeView

### 4. [ ] Verify Firebase

- Check user created and signed in
- Profile saved to Firestore

**Progress: 1/4**

### 2. [ ] Simplify RegisterView onVerified callback

- Remove popUntil, registered modal, photo upload (move elsewhere)
- Just call authVM.registerWithEmail → userVM.createProfile → return

### 3. [ ] Test registration flow

- Register new user → enter OTP → verify → auto sign-in → HomeView

### 4. [ ] Verify Firebase

- Check user created and signed in
- Profile saved to Firestore

**Progress: 0/4**
