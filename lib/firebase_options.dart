import 'package:firebase_core/firebase_core.dart';

/// Web app "The Hatch" registered in the store's Firebase project (pageecommerceapp).
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBtfnHECW1Re8yiem6n5lzLIkup2xaKMdM',
    authDomain: 'pageecommerceapp.firebaseapp.com',
    projectId: 'pageecommerceapp',
    storageBucket: 'pageecommerceapp.appspot.com',
    messagingSenderId: '603181766410',
    appId: '1:603181766410:web:720cf74fc41588a1c10cf3',
    measurementId: 'G-SHJPBLM5Z2',
  );
}
