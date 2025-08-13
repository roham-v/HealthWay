# HealthWay (Offline-only)

نسخه آفلاین اپلیکیشن «راه سلامتی». شامل:
- چندبیماره (مدیریت بیماران)
- فرم‌های ثبت: قند، فشار(به‌همراه ضربان)، اکسیژن(به‌همراه ضربان)، انسولین، ادرار(حجم/رنگ/نوع سوند)، دارو، وعده غذایی، ویزیت پزشک
- داشبورد روزانه ساده
- ذخیره‌سازی محلی با Hive
- تاریخ شمسی با shamsi_date
- راست‌به‌چپ کامل

## اجرا
```bash
flutter pub get
flutter run -d chrome  # برای وب تستی
flutter run            # برای دیوایس/شبیه‌ساز
```

## ساخت APK
```bash
flutter build apk --release
# فایل خروجی: build/app/outputs/flutter-apk/app-release.apk
```

## انتشار در GitHub
```bash
git init
git add .
git commit -m "HealthWay offline initial"
git branch -M main
git remote add origin https://github.com/roham-v/HealthWay.git
git push -u origin main
```
