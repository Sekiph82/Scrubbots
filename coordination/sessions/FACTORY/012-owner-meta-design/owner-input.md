Owner input pasted by Şekip in the orchestrator chat on 2026-10-22 (verbatim, Turkish). Genuine owner design decision.

SCRUBBOTS | Card Packs, Robots, Gift Bar ve Achievements Tasarımı

ScrubBots'un mevcut ekonomisini, 135 kartlık Collection sistemini, 10 robotluk kadrosunu, Gift Meter ödüllerini ve Achievements altyapısını dikkate alarak bir ilerleme sistemi tasarladım.

Bence en iyi yaklaşım, bu dört özelliğin oyuncuya farklı zamanlarda sunulması ama kazanılmış ödüllerin hiçbir zaman kaybolmaması.

Aşağıdaki seviyeleri tasarım kararım olarak belirliyorum. Bunlar henüz GitHub'a uygulanmış yeni kurallar değil.

1. 🔓 Özelliklerin açılış seviyeleri
Özellik	Açılış seviyesi	Kararım
🎁 Gift Bar	Level 0001	Oyunun başından itibaren açık
🃏 Card Packs	Level 0020	Collection ile birlikte açılır
🤖 Robots	Level 0025	Robot koleksiyonu ve parçalar görünür
🏆 Achievements	Level 0035	Başarılar ekranı açılır

Bu sıralamanın arkasındaki düşünce şu:

Gift Bar: Kesinlikle başlangıçtan itibaren açık olmalı. Oyuncu ilk kazancından itibaren çubuğun dolduğunu görmeli.

Card Packs: Level 20'de açılması iyi bir tercih. Oyuncu önce oyunu öğrenir, sonra kart biriktirmeye başlar.

Robots: Level 25'te açılır. Scrubby zaten başlangıç robotudur. Oyuncu diğer robotları, yeteneklerini ve topladığı Bot Parts miktarını görebilir.

Achievements: Level 35'te açılır. Ancak başarıların istatistikleri Level 1'den itibaren kaydedilir. Böylece Level 35'e gelen oyuncu daha önce tamamladığı başarıları da görür.

Önemli: Level 20'den önce kazanılan Card Packs, bekleyen paket envanterinde saklanmalı. Level 20'de açılabilir hale gelmeli. Yeni kart veya ödül oluşturulmamalı, önceden kazanılmış paketler kaybolmamalı.

2. 🃏 CARD PACKS VE 135 KARTLIK KOLEKSİYON

ScrubBots'ta şu anda:

15 Collection Set bulunuyor.
Her sette 9 kart var.
Toplam 135 kart bulunuyor.
Standard Pack 3 kart, Premium Pack 5 kart içeriyor.
Kartların Common, Rare, Epic ve Legendary nadirlikleri bulunuyor.

Bence kartların tamamını ilk günden rastgele oyuncunun önüne koymak yerine, World ve Level ilerlemesine bağlı tematik kart tanıtımları oluşturmalıyız.

15 Collection Set için planım
Set	Collection	Öne çıktığı Level aralığı
01	Meet the Scrubbots	0020–0040
02	Cleaning Crew	0050–0140
03	Mess Monsters	0601–0691
04	Color Bots	0151–0241
05	Scrubbot Workshop	0751–0841
06	Bathroom Mayhem	0451–0541
07	Kitchen Chaos	1801–1891
08	Garage Grime	0901–0991
09	Sewer Squad	0301–0391
10	Clean City	1201–1291
11	Jungle Cleanup	1651–1741
12	Bath Time Blitz	2401–2491
13	Underwater Heroes	1351–1441
14	Space Cleaners	2251–2341
15	Ultimate Cleaners	2851–2971

Bu aralıklar kartların öne çıkarıldığı dönemlerdir. Otomatik olarak bütün kartların o seviyelerde verilmesi anlamına gelmez.

Örneğin World 03: Neon Sewers sırasında Sewer Squad koleksiyonunun ön plana çıkması güzel olur.

Hangi kart hangi Level'de görünecek?

Bunu da tasarlayabiliriz.

Örneğin ilk koleksiyonumuz:

SET 01: Meet the Scrubbots

Level	Card	Rarity	Planlanan sunum
0020	Scrubby	Common	İlk kart ödülü
0022	Bubbles	Common	Öne çıkan kart
0024	Moppy	Common	Öne çıkan kart
0026	Brushy	Common	Öne çıkan kart
0029	Squeegee	Rare	Öne çıkan kart
0032	Spark	Rare	Öne çıkan kart
0035	Turbo Scrubby	Epic	Öne çıkan kart
0038	Captain Clean	Epic	Öne çıkan kart
0040	Scrubmaster X	Legendary	Koleksiyon finali

Ben bu sistemi ikiye ayırırdım.

Normal kart kazanımı: Oyuncu Standard ve Premium paketlerini açar. Mevcut rastgele kart, nadirlik ve duplicate kuralları devam eder.

Featured Card: Belirli seviyelerde bir kart ön plana çıkar. İlerleme ödülü verilecekse bu ayrıca tanımlanır.

İlk kart olan Scrubby'yi Level 20'de garanti etmeyi öneriyorum. Diğer sekiz kartın aynı seviyelerde otomatik verilmesini önermiyorum; bu, kart toplamanın heyecanını azaltabilir.

Bunun yerine Level 30 ve 40 gibi kilometre taşlarında Set 01'de henüz bulunmayan bir kartı garanti eden ödüller kullanabiliriz.

Bu sayede ilk koleksiyonun erken tamamlanması teşvik edilir. Oyuncu yine paket açarak daha hızlı ilerleyebilir.

Diğer 126 kart için sistem

Diğer 14 setin her birinde dokuz kartı, öne çıkma döneminin başlangıcından itibaren şu göreli konumlarda tanıtmayı öneriyorum:

+0 / +10 / +20 / +30 / +40 / +50 / +60 / +70 / +90

Kart sıralaması ilgili setin mevcut kataloğunu takip eder. İlk Set 01 ise yukarıdaki özel hızlı takvimi kullanır.

Bu, 135 kartın tamamı için üretilebilir bir Featured Card takvimi oluşturur. Gerçek kazanım yine paket ve açıkça tanımlanan garanti ödüller üzerinden gerçekleşir.

Alternatifler
Model	Avantaj	Dezavantaj
A. Tamamen rastgele kartlar	Sürpriz yüksek	Oyuncu istediği koleksiyonu geç tamamlayabilir
B. Featured Set + rastgele paketler	Dengeli ilerleme	Öne çıkan kart takvimi gerekir
C. Her kart belirli Level'de garanti	Oyuncu tam olarak ne kazanacağını bilir	Paket açmanın heyecanı azalır

Tercihim: B.

3. 🤖 ROBOTS VE BOT PARTS PLANI

Mevcut GitHub sisteminde 10 robot bulunuyor.

Scrubby başlangıçta açık. Diğer robotları açmak için 250 Bot Parts gerekiyor.

Bence mevcut 250 Bot Parts ekonomisini korumalıyız.

Robotların önerilen açılış sırası
Robot	Robot adı	Hedef Level	Durum
01	Scrubby	0001	Başlangıçta açık
02	Moppy	~0150	Bot Parts ile
03	Bubbles	~0300	Bot Parts ile
04	Spark	~0450	Bot Parts ile
05	Squeegee	~0600	Bot Parts ile
06	Dusty	~0750	Bot Parts ile
07	Rinse	~0900	Bot Parts ile
08	Polly	~1050	Bot Parts ile
09	Clippy	~1200	Bot Parts ile
10	Atlas	~1350	Bot Parts ile

Bu tablo hedef ilerleme planıdır, sabit açılış kilidi değildir.

Bot Parts kazanımı oyuncunun ilk tamamlamalarına, Win Streak başarısına, Gift Bar ödüllerine ve Collection tamamlamalarına bağlı olduğu için robotlar hedef seviyelerden önce veya sonra açılabilir.

Her robotun parçalarını ayrı ayrı gösterelim mi?

Bence evet!

Şu anda Bot Parts genel bir kaynak. Yani oyuncunun kazandığı parça gerçekten bir tekerlek, kol veya sensör olarak kaydedilmiyor.

Ama buna gerek kalmadan çok güzel bir görsel sistem kurabiliriz.

Örnek: Moppy montaj ilerlemesi
Bot Parts ilerlemesi	Görsel parça
50/250	Moppy Wheels
100/250	Cleaning Arms
150/250	Water Tank
200/250	Sensor Head
250/250	Moppy Unlocked!

Böylece robot koleksiyonunda bir montaj animasyonu gösterilir.

Oyuncu 50 Bot Parts biriktirdiğinde tekerlekler ortaya çıkar. 100'e ulaştığında kollar eklenir. Son aşamada robot tamamlanır.

Bu sistemde parçalar ayrı bir harcanabilir para birimi değildir. Mevcut Bot Parts ilerlemesinin görsel temsilidir.

Böylece mevcut ekonomi değişmez.

Level bazlı alternatif

Moppy için yaklaşık olarak şu seviyeleri hedefleyebiliriz:

Level 0030: Wheels
Level 0060: Arms
Level 0090: Water Tank
Level 0120: Sensor Head
Level 0150: Moppy Unlock

Ancak bu modelde seviyeler kesin olmak yerine tahminî olmalı. Çünkü 250 Bot Parts'a ulaşma hızı oyuncuya göre değişir.

Benim tercihim, parçaların sabit Level'de değil, Bot Parts ilerleme eşiklerinde ortaya çıkması.

4. 🎁 GIFT BAR

Kesin kararım: Gift Bar Level 0001'den itibaren açık.

Bence burada yeni bir ödül sistemi oluşturmamıza gerek yok. GitHub'da zaten güzel bir yapı var.

Gift Meter yalnızca kazanılan Win Streak bonuslarından ilerliyor.

Mevcut ödüller:

Gift Meter	Ödül
10	1 Bot Part + Standard Card Pack
50	1 Bot Part + Random Booster Charge
250	2 Bot Parts + 100 SB + Standard Card Pack
500	2 Bot Parts + 250 SB + seçilen Booster Charge + Standard Card Pack
1000	4 Bot Parts + 500 SB + 2 Booster Charges + Premium Pack + guaranteed-new Card

Bu kuralları aynen korumayı öneriyorum.

Yeni oyuncu Gift Bar'ı ilk Home ekranından itibaren görmeli.

Card Packs henüz açılmadıysa kazanılan kart paketleri bekleyen envanterde kalmalı. Oyuncu bunları Level 20'de açabilir.

Bence Gift Bar'ın erken açık olması özellikle önemli. Çünkü oyuncuya ilk dakikadan itibaren ikinci bir ilerleme hedefi sunuyor.

5. 🏆 ACHIEVEMENTS SİSTEMİ

Bence Achievements, ScrubBots'un uzun ömürlü ilerleme sistemlerinden biri olmalı.

Özellikle 3.000 Level planladığımız için başarıları yalnızca ilk 100 bölüme yığmamalıyız.

Achievements ekranı Level 0035'te açılacak. Ancak tüm istatistikler Level 0001'den itibaren tutulacak.

Şu anda GitHub'da sekiz başlangıç başarısı bulunuyor. Bunları koruyarak sistemi genişletmeyi öneriyorum.

A. Level Achievements
Achievement	Şart	Açılabileceği Level
Clean Start	İlk Level'i tamamla	0001
Tidy Ten	10 Level tamamla	0010
Spotless Fifty	50 Level tamamla	0050
Park Protector	150 Level tamamla	0150
District Defender	300 Level tamamla	0300
Five Worlds Clean	750 Level tamamla	0750
Halfway Hero	1.500 Level tamamla	1500
Ultimate Scrubbot	3.000 Level tamamla	3000

Bu başarılar tamamen deterministik. İlk kez tamamlanan progression seviyeleri sayılır, tekrar oynama ilerleme kazandırmaz.

B. Collection Achievements
Achievement	Şart	Tahmini dönem
First Discovery	İlk benzersiz kartını kazan	Level 20+
Card Collector	9 benzersiz kart topla	Level 30–100
Card Hunter	25 benzersiz kart topla	Level 100–350
Master Collector	75 benzersiz kart topla	Level 800–1800
Complete Collection	135 benzersiz kart topla	Level 2000–3000
First Set	Bir koleksiyonu tamamla	Level 20–80
Triple Collector	3 koleksiyon tamamla	Level 200–600
Collection Champion	8 koleksiyon tamamla	Level 900–2000
Collection Legend	15 koleksiyon tamamla	Level 2500–3000

Tahmini dönemler hedef niteliğinde. Gerçek tamamlanma zamanı kazanılan paketlere ve kart tekrarlarına bağlı olacak.

C. Robot Achievements
Achievement	Şart	Tahmini Level
New Recruit	2 robot aç	~0150
Robot Trio	3 robot aç	~0300
Half the Crew	5 robot aç	~0600
Robot Squad	7 robot aç	~0900
Full Scrubbot Team	10 robotun tamamını aç	~1350

Bu başarılar mevcut robots_unlocked istatistiğiyle izlenebilir.

D. Skill Achievements
Achievement	Şart	Tahmini dönem
Hot Streak	5 galibiyet serisi	İlk 20 Level
Unstoppable	15 galibiyet serisi	Level 20–100
Perfect Rhythm	30 galibiyet serisi	Level 50–200
Streak Master	50 galibiyet serisi	Level 100–400
Bare Hands	Booster kullanmadan 10 bölüm kazan	Level 20–100
Pure Skill	Booster kullanmadan 50 bölüm kazan	Level 100–400
First Try Hero	5 bölümü art arda ilk denemede kazan	Level 10–100
Flawless Cleaner	10 bölümü art arda ilk denemede kazan	Level 30–250

Bu başarılar belirli seviyelerde zorunlu açılmayacak. Oyuncunun becerisine göre açılacak.

E. Gift Bar Achievements

Bence iki özel başarı daha eklemeliyiz.

Achievement	Şart	Tahmini dönem
Gift Hunter	Gift Bar'dan ilk ödülünü al	İlk 10 Level
Gift Master	Gift Meter'da ilk 1000 puanlık döngüyü tamamla	Oyuncunun Win Streak performansına bağlı

Bunların mevcut başarı sistemine eklenmesi için Gift Meter istatistiklerinin achievement sistemine bağlanması gerekiyor.

6. Achievements ödülleri ne olsun?

Burada iki alternatif görüyorum.

Alternatif A: Kozmetik ödüller

Başarı tamamlandığında özel rozet, profil çerçevesi veya Collection vitrini süslemesi açılır.

Bu yöntemde Scrub Bucks ve Bot Parts ekonomisi etkilenmez.

Alternatif B: Ekonomi ödülleri

Başarılar SB, Booster Charges, Bot Parts veya Card Packs verir.

Bu sistem daha güçlü motivasyon sağlayabilir ama mevcut ödül ekonomisini yeniden dengelememiz gerekir.

Benim tercihim Alternatif A.

Özellikle büyük başarıların profil ekranında gösterilebilen prestij rozetleri olması hoşuma gidiyor.

GitHub'daki mevcut Achievements sistemi henüz ödül vermiyor. Kozmetik ödüller de yeni bir özellik olarak ayrıca uygulanmalı.

7. Nihai önerim
Sistem	Karar	Temel kural
🎁 Gift Bar	Level 0001	Baştan açık, mevcut ödül ekonomisi
🃏 Card Packs	Level 0020	15 set, 135 kart, Featured Card takvimi
🤖 Robots	Level 0025	Robot ekranı açılır, robotlar 250 Bot Parts ile kazanılır
🏆 Achievements	Level 0035	32 başarı, istatistikler Level 1'den itibaren
En önemli tasarım tercihlerim

Kartlar: Oyuncuyu tek bir seviyede belirli kartı almaya zorlamayalım. Kartların öne çıktığı seviyeleri planlayalım; paketlerle rastgele kart kazanımı devam etsin. Yalnızca seçilmiş kilometre taşlarında garantili kart verelim.

Robotlar: Robotları sabit seviyelerde ücretsiz açmayalım. Mevcut 250 Bot Parts sistemini kullanalım. Robot montajını beş görsel aşamada gösterelim.

Gift Bar: İlk saniyeden itibaren açık olsun. Mevcut 10/50/250/500/1000 ödülleri korunsun.

Achievements: Level 35'te açılan, başlangıçtan itibaren ilerlemeyi kaydeden ve 3.000 Level boyunca hedef sunan 32 başarıdan oluşsun.

Böylece bu dört sistem birbirini tamamlar. Gift Bar kart ve robot ilerlemesine katkıda bulunur, Card Packs koleksiyon hedefi yaratır, Robots uzun vadeli motivasyon sağlar, Achievements ise bütün bu başarıları görünür hale getirir.
