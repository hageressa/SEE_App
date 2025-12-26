# Firebase Security Rules

This directory contains security rules for Firebase services used in the SEE App.

## Fixing Firebase Permission Issues

The Firebase permission denied errors are likely due to restrictive security rules in your Firebase project. To fix this:

1. Make sure you have the Firebase CLI installed:
   ```
   npm install -g firebase-tools
   ```

2. Log in to Firebase:
   ```
   firebase login
   ```

3. Initialize Firebase in your project (if not already done):
   ```
   firebase init
   ```
   - Select Firestore and any other services you're using
   - Choose your project
   - When asked about rules files, use the ones in this directory

4. Deploy the security rules:
   ```
   firebase deploy --only firestore:rules
   ```

## Security Rules

The current rules in `firestore.rules` allow:
- Any authenticated user to read/write all documents
- Public read access to the `public` collection

For a production application, you should implement more granular security rules that restrict access based on user roles and document ownership.

## Testing Firebase Permissions

You can test Firebase permissions from the app using the System Diagnostics tool:
1. Open the app
2. Go to login screen
3. Tap the diagnostics icon
4. Use the Firebase Permissions Test feature 