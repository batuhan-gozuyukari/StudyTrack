 StudyTrack – Firebase Tabanlı Çalışma Süresi Takip & Motivasyon Uygulaması
1. Projenin Amacı

StudyTrack, öğrencilerin günlük ve haftalık çalışma sürelerini takip etmelerini, ders bazlı çalışmalarını kaydetmelerini ve performanslarını anlamalarına yardımcı olmayı amaçlayan Flutter tabanlı bir mobil uygulamadır.
Uygulama ayrıca motivasyon amaçlı topluluk etkileşimi sağlar (paylaşım, yorum, beğeni).

Bu proje Mobil Programlama Final Ödevi kapsamında geliştirilmiştir.



2. Proje Senaryosu

Final dönemine hazırlanan bir öğrencinin hangi derse ne kadar çalıştığını bilmediği için verimsiz hissetmesi üzerine senaryo kurulmuştur.

Öğrenci uygulamaya giriş yapar, günlük hedef belirler, zamanlayıcıyla çalışma oturumu başlatır ve bitirdiği oturumları kaydeder.
Son 7 güne ait istatistiklere bakabilir ve topluluk ekranında motivasyon amaçlı paylaşım yapabilir.

Bu senaryo gerçek hayattaki öğrenci kullanımına yönelik tasarlanmıştır.



3. Kullanılan Teknolojiler

Frontend:
Flutter
Dart

Backend & Bulut Servisleri (Firebase):

Firebase Authentication
Cloud Firestore
Firebase Storage (Profil fotoğrafı ve aktiviteler için)
Firebase Core

Diğer:

StreamBuilder ile gerçek zamanlı veri işleme

Stateful yaklaşım (setState)

Firestore sorguları (orderBy, where, filter, map)




4. Firestore Veri Modeli

Projede aşağıdaki koleksiyonlar kullanılmıştır:

users {
    uid: string,
    name: string,
    email: string,
    weeklyGoalMinutes: number,
    dailyGoalMinutes: number,
    profilePic: string,
}
study_sessions {
    userId: string,
    lesson: string,
    durationMinutes: number,
    date: Timestamp,
}
posts {
    userId: string,
    userName: string,
    userAvatar: string,
    message: string,
    date: Timestamp,
    activityImage: string?,
    activityLabel: string?,
    likes: number,
    likedBy: array<string>,
    comments: array<object>,
}
Bu tasarım sayesinde: çalışma oturumlarıkullanıcılartopluluk paylaşımlarıhem ayrık hem de ilişkilendirilebilir şekilde tutulmaktadır.



5. Uygulama Ekranları

Giriş/Kayıt → Authentication + Şifre sıfırlama
Dashboard → Günlük hedef ve çalışma süresi
Timer → Zamanlayıcı ile oturum kaydetme
İstatistikler → Son 7 gün + ders bazlı analiz
Topluluk (Community) → Paylaşım, yorum, beğeni
Profil → Kullanıcı bilgisi ve profil fotoğrafı güncelleme



6. Video Tanıtım (Final)

Uygulamanın çalışır halinin tanıtım videosu:
 https://www.youtube.com/watch?v=FHy7RldUs2Q

Videoda:
-istenirlerin gösterimi
-ekranlar arası geçiş
-firebase operasyonları
-hedef ve istatistik hesaplama
yer almaktadır.

7. Kurulum & Çalıştırma

Projeyi klonladıktan sonra:
flutter pub get
Ardından çalıştırmak için:
flutter run


Firebase configs firebase_options.dart dosyasında bulunmaktadır.
Android için ek kurulum gerekirse:
flutter pub run build_runner build

8. Proje Klasör Yapısı
lib/
  screens/
  services/
  firebase_options.dart
android/
ios/
pubspec.yaml
README.md


build/, .dart_tool/, Pods/ gibi klasörler projeye dahil edilmemiştir.

9. Geliştirici Notu

Bu proje tek geliştirici tarafından gerçekleştirilmiştir.
Mobil programlama dersi kapsamında Flutter + Firebase entegrasyonu uygulamalı olarak öğrenilmiştir.
Zamanlayıcı, istatistik hesaplama, topluluk akışı ve kullanıcı hedefleri gibi senaryolar gerçeğe yakın şekilde modellenmiştir.

10. --Öğrenci Bilgisi--

Ad Soyad: Batuhan Gözüyukarı
Ögrenci No 23060515
Ders: Mobil Programlama
Dönem: 2025 - Dönem Sonu Projesi



