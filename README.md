# DHouston

Nasa space apps yarışmasında yapacağımız oyun için açılan depo

## Mars Colony

NASA Space Apps Challenge 2026, "Space Mission Design Game". 7-12 yaş için, tarayıcıda oynanan, sıra tabanlı bir Mars kolonisi yönetim oyunu. Kaynaklar sınırlı, her seçimin bir bedeli var, sayılar gerçek NASA verisine dayanıyor.

### Projeyi açmak

1. Godot **4.3 veya daha yeni** bir sürümü indir (Standard sürüm, .NET/C# sürümü değil): https://godotengine.org/download
2. Godot'u aç, **Import** de, bu klasördeki `project.godot` dosyasını seç.
3. Sağ üstteki **Play** (F5) tuşuna bas.

### Klasörler

- `scenes/` oyun sahneleri (`main.tscn` ilk açılan sahne)
- `scripts/` GDScript dosyaları
- `.github/workflows/pages.yml` her `main` güncellemesinde web sürümünü otomatik derler ve yayınlar

### Web'de yayınlama

Depoda **Settings → Pages → Source: GitHub Actions** seçili olmalı. Sonra `main` dalına her gönderimde (push) oyun otomatik derlenir. Adres: `https://nyxborne9.github.io/DHouston/`

### Kurallar

- Sadece GDScript kullanıyoruz. Godot 4'te C# projeleri web'e aktarılamıyor.
- Render modu **Compatibility** kalacak (web için gerekli).
- Kullanılan her veri, görsel ve ses `CREDITS.md` dosyasına yazılır. NASA kuralları bunu zorunlu kılıyor.
