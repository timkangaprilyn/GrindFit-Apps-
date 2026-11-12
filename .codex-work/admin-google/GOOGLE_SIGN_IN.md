# Admin sign-in

The admin portal uses email/password only. Google sign-in is reserved for the
member Android app. There is no Google sign-in button or popup flow here.

Enable Email/Password in Firebase Authentication. Staff access still requires
a trusted admin or trainer custom claim, granted through the Firebase Admin
SDK. Email addresses and Firestore profile roles do not grant staff access.

Test password login with admin and trainer accounts, rejection of a member
account, and sign out. Firebase settings and claims were not deployed by this
change.
