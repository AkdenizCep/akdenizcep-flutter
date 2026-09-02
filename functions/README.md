# Akdeniz Cep Cloud Functions

Profil fotoğrafı callable fonksiyonları `europe-west1` bölgesinde çalışır ve
Node.js 22 kullanır.

## İlk kurulum

Firebase projesi Blaze planında olmalıdır. Cloudinary değerlerini kaynak
kontrolüne eklemeden Secret Manager'a kaydet:

```powershell
firebase functions:secrets:set CLOUDINARY_CLOUD_NAME
firebase functions:secrets:set CLOUDINARY_API_KEY
firebase functions:secrets:set CLOUDINARY_API_SECRET
```

Ardından test et ve dağıt:

```powershell
Set-Location functions
npm install
npm test
Set-Location ..
firebase deploy --only functions:setProfilePhoto,functions:removeProfilePhoto,firestore:rules
```

Cloudinary API secret hiçbir zaman Flutter `--dart-define` değerlerine veya
istemci kaynak koduna eklenmemelidir.
