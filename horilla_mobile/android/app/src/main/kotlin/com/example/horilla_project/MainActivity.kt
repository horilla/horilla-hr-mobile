package com.cybrosys.horilla_project

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth's Android side needs a FragmentActivity to host
// androidx.biometric.BiometricPrompt -- plain FlutterActivity isn't one and
// crashes with a ClassCastException the first time authenticate() is called.
class MainActivity : FlutterFragmentActivity()
