# Biar OkHttp nggak dihapus paksa sama R8
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Tambahan buat BouncyCastle & Conscrypt yang error tadi
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**