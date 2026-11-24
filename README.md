# APPDA72 Fashion Store — Admin

لوحة تحكم Flutter Web لمتجر فاشون APPDA72 (GetX imperative + Firebase).

## GitHub Pages (Web)

بعد التفعيل والنشر:

**https://youssef999.github.io/APPDA72-FASHION-STORE-ADMIN/**

البناء المحلي للويب:

```bash
flutter pub get
flutter build web --release --base-href "/APPDA72-FASHION-STORE-ADMIN/"
```

فرع `gh-pages` يحتوي مخرجات `build/web` (Pages Source = Deploy from branch → `gh-pages` / root).  
كل push على `main` يشغّل workflow يبني Flutter Web ويرفعه على `gh-pages`.

## تشغيل محلي

```bash
flutter pub get
flutter run -d chrome
```
