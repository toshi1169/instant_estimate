import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_language.dart';
import 'filipino_translations.dart';
import 'indonesian_translations.dart';
import 'myanmar_translations.dart';
import 'vietnamese_translations.dart';

class AppLocalizations {
  const AppLocalizations(this.appLanguage);

  final AppLanguage appLanguage;

  bool get isJapanese => appLanguage == AppLanguage.japanese;
  bool get isSimplifiedChinese => appLanguage == AppLanguage.simplifiedChinese;
  bool get isTraditionalChinese =>
      appLanguage == AppLanguage.traditionalChinese;
  bool get isVietnamese => appLanguage == AppLanguage.vietnamese;
  bool get isIndonesian => appLanguage == AppLanguage.indonesian;
  bool get isFilipino => appLanguage == AppLanguage.filipino;
  bool get isMyanmar => appLanguage == AppLanguage.myanmar;

  // English is also the safe fallback while a newly added language is being
  // translated screen by screen. This prevents Japanese text leaking into a
  // non-Japanese locale.
  bool get isEnglish => !isJapanese;

  String _pick({
    required String japanese,
    required String english,
    required String simplifiedChinese,
    String? traditionalChinese,
    String? vietnamese,
    String? indonesian,
    String? filipino,
    String? myanmar,
  }) => switch (appLanguage) {
    AppLanguage.japanese => japanese,
    AppLanguage.english => english,
    AppLanguage.simplifiedChinese => simplifiedChinese,
    AppLanguage.traditionalChinese => traditionalChinese ?? english,
    AppLanguage.vietnamese =>
      vietnamese ?? vietnameseTranslations[japanese] ?? english,
    AppLanguage.indonesian =>
      indonesian ?? indonesianTranslations[japanese] ?? english,
    AppLanguage.filipino =>
      filipino ?? filipinoTranslations[japanese] ?? english,
    AppLanguage.myanmar => myanmar ?? myanmarTranslations[japanese] ?? english,
  };

  String choose({
    required String japanese,
    required String english,
    required String simplifiedChinese,
    String? traditionalChinese,
    String? vietnamese,
    String? indonesian,
    String? filipino,
    String? myanmar,
  }) => _pick(
    japanese: japanese,
    english: english,
    simplifiedChinese: simplifiedChinese,
    traditionalChinese: traditionalChinese,
    vietnamese: vietnamese,
    indonesian: indonesian,
    filipino: filipino,
    myanmar: myanmar,
  );

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(AppLanguage.japanese);
  }

  String get appTitle => _pick(
    japanese: 'インスタント見積',
    english: 'Instant Estimate',
    simplifiedChinese: '即时估算',
    traditionalChinese: '即時估算',
  );
  String get language => _pick(
    japanese: '言語',
    english: 'Language',
    simplifiedChinese: '语言',
    traditionalChinese: '語言',
  );
  String get chooseLanguage => _pick(
    japanese: '言語を選択',
    english: 'Choose language',
    simplifiedChinese: '选择语言',
    traditionalChinese: '選擇語言',
  );
  String get languageGuidance => _pick(
    japanese: 'アプリで使用する言語を選んでください。後から設定で変更できます。',
    english:
        'Select the language used in the app. You can change it later in Settings.',
    simplifiedChinese: '请选择应用中使用的语言。之后可在设置中更改。',
    traditionalChinese: '請選擇應用程式使用的語言。之後可在設定中變更。',
  );
  String get continueLabel => _pick(
    japanese: '次へ',
    english: 'Continue',
    simplifiedChinese: '继续',
    traditionalChinese: '繼續',
  );
  String get japanese => _pick(
    japanese: '日本語',
    english: 'Japanese',
    simplifiedChinese: '日语',
    traditionalChinese: '日文',
  );
  String get english => 'English';
  String get simplifiedChinese => '简体中文';
  String get traditionalChinese => '繁體中文';
  String get vietnamese => 'Tiếng Việt';
  String get indonesian => 'Bahasa Indonesia';
  String get filipino => 'Filipino';
  String get myanmar => 'မြန်မာ';
  String get occupationTitle => _pick(
    japanese: '業種を選択',
    english: 'Choose occupation',
    simplifiedChinese: '选择行业',
    traditionalChinese: '選擇行業',
  );
  String get mainOccupation => _pick(
    japanese: '主な業種',
    english: 'Main occupation',
    simplifiedChinese: '主要行业',
    traditionalChinese: '主要行業',
    vietnamese: 'Ngành nghề chính',
    indonesian: 'Bidang pekerjaan utama',
    filipino: 'Pangunahing larangan ng trabaho',
    myanmar: 'အဓိကလုပ်ငန်းအမျိုးအစား',
  );
  String get saveOccupation => _pick(
    japanese: '業種を保存',
    english: 'Save occupation',
    simplifiedChinese: '保存行业',
    traditionalChinese: '儲存行業',
    vietnamese: 'Lưu ngành nghề',
    indonesian: 'Simpan bidang pekerjaan',
    filipino: 'I-save ang larangan ng trabaho',
    myanmar: 'လုပ်ငန်းအမျိုးအစားကို သိမ်းမည်',
  );
  String get calculatorDigitLimitNotice => _pick(
    japanese: '最大20桁まで入力できます',
    english: 'You can enter up to 20 digits.',
    simplifiedChinese: '最多可输入20位数字',
    traditionalChinese: '最多可輸入20位數字',
    vietnamese: 'Bạn có thể nhập tối đa 20 chữ số.',
    indonesian: 'Anda dapat memasukkan maksimal 20 digit.',
    filipino: 'Hanggang 20 digit ang maaaring ilagay.',
    myanmar: 'ဂဏန်း ၂၀ လုံးအထိ ထည့်သွင်းနိုင်သည်။',
  );
  String get occupationPrompt => _pick(
    japanese: 'あなたの主な業種を選んでください',
    english: 'Select your main occupation',
    simplifiedChinese: '请选择您的主要行业',
    traditionalChinese: '請選擇您的主要行業',
  );
  String get occupationGuidance => _pick(
    japanese: '表示する計算機能や見積項目の初期設定に使用します。後から設定で変更できます。',
    english:
        'This is used to prepare the initial calculators and estimate items. You can change it later in Settings.',
    simplifiedChinese: '用于设置初始计算功能和估算项目。之后可在设置中更改。',
    traditionalChinese: '用於設定初始計算功能和估算項目。之後可在設定中變更。',
  );
  String get startWithOccupation => _pick(
    japanese: 'この業種で始める',
    english: 'Start with this occupation',
    simplifiedChinese: '以此行业开始',
    traditionalChinese: '以此行業開始',
  );

  String occupation(String value) => switch (value) {
    '建築監督' => _pick(
      japanese: value,
      english: 'Building supervisor',
      simplifiedChinese: '建筑监理',
      traditionalChinese: '建築監督',
      vietnamese: 'Giám sát xây dựng',
      indonesian: 'Pengawas bangunan',
      filipino: 'Tagapangasiwa ng gusali',
      myanmar: 'အဆောက်အအုံ ကြီးကြပ်သူ',
    ),
    '土木監督' => _pick(
      japanese: value,
      english: 'Civil supervisor',
      simplifiedChinese: '土木监理',
      traditionalChinese: '土木監督',
      vietnamese: 'Giám sát công trình dân dụng',
      indonesian: 'Pengawas sipil',
      filipino: 'Tagapangasiwa ng civil works',
      myanmar: 'မြို့ပြလုပ်ငန်း ကြီးကြပ်သူ',
    ),
    '建築基礎' => _pick(
      japanese: value,
      english: 'Building foundations',
      simplifiedChinese: '建筑基础',
      traditionalChinese: '建築基礎',
      vietnamese: 'Công tác móng',
      indonesian: 'Pekerjaan fondasi',
      filipino: 'Gawaing pundasyon',
      myanmar: 'အုတ်မြစ်လုပ်ငန်း',
    ),
    '外構' => _pick(
      japanese: value,
      english: 'Exterior works',
      simplifiedChinese: '室外工程',
      traditionalChinese: '外構工程',
      vietnamese: 'Công trình ngoại thất',
      indonesian: 'Pekerjaan eksterior',
      filipino: 'Gawaing panlabas',
      myanmar: 'ပြင်ပလုပ်ငန်း',
    ),
    '内装' => _pick(
      japanese: value,
      english: 'Interior works',
      simplifiedChinese: '室内装修',
      traditionalChinese: '室內裝修',
      vietnamese: 'Công tác nội thất',
      indonesian: 'Pekerjaan interior',
      filipino: 'Gawaing panloob',
      myanmar: 'အတွင်းပိုင်းလုပ်ငန်း',
    ),
    '多能工' => _pick(
      japanese: value,
      english: 'Multi-skilled worker',
      simplifiedChinese: '多技能工',
      traditionalChinese: '多技能工',
      vietnamese: 'Thợ đa năng',
      indonesian: 'Pekerja multikeahlian',
      filipino: 'Manggagawang maraming kasanayan',
      myanmar: 'ကျွမ်းကျင်မှုမျိုးစုံလုပ်သား',
    ),
    _ => _pick(
      japanese: value,
      english: 'Other',
      simplifiedChinese: '其他',
      traditionalChinese: '其他',
      vietnamese: 'Khác',
      indonesian: 'Lainnya',
      filipino: 'Iba pa',
      myanmar: 'အခြား',
    ),
  };

  String get settings => _pick(
    japanese: '設定',
    english: 'Settings',
    simplifiedChinese: '设置',
    traditionalChinese: '設定',
  );
  String get buttonSettings => _pick(
    japanese: 'ボタン設定',
    english: 'Button settings',
    simplifiedChinese: '按钮设置',
    traditionalChinese: '按鈕設定',
    vietnamese: 'Cài đặt nút',
    indonesian: 'Pengaturan tombol',
    filipino: 'Mga setting ng button',
    myanmar: 'ခလုတ် ဆက်တင်များ',
  );
  String get calculatorTapSound => _pick(
    japanese: 'タップ音',
    english: 'Tap sound',
    simplifiedChinese: '点击音',
    traditionalChinese: '點按音效',
    vietnamese: 'Âm thanh khi chạm',
    indonesian: 'Suara ketukan',
    filipino: 'Tunog ng pag-tap',
    myanmar: 'နှိပ်သံ',
  );
  String get calculatorTapHaptics => _pick(
    japanese: 'タップ時バイブレーション',
    english: 'Vibration on tap',
    simplifiedChinese: '点击时振动',
    traditionalChinese: '點按時震動',
    vietnamese: 'Rung khi chạm',
    indonesian: 'Getar saat diketuk',
    filipino: 'Vibration kapag nag-tap',
    myanmar: 'နှိပ်သည့်အခါ တုန်ခါမှု',
  );
  String get dataBackup => _pick(
    japanese: 'データのバックアップ',
    english: 'Data backup',
    simplifiedChinese: '数据备份',
    traditionalChinese: '資料備份',
    vietnamese: 'Sao lưu dữ liệu',
    indonesian: 'Cadangan data',
    filipino: 'Backup ng data',
    myanmar: 'ဒေတာအရန်သိမ်းခြင်း',
  );
  String get dataBackupSettingsSubtitle => _pick(
    japanese: '機種変更に備えてバックアップを書き出します',
    english: 'Export a backup for moving to another device',
    simplifiedChinese: '导出备份以便更换设备',
    traditionalChinese: '匯出備份以便更換裝置',
    vietnamese: 'Xuất bản sao lưu để chuyển sang thiết bị khác',
    indonesian: 'Ekspor cadangan untuk pindah perangkat',
    filipino: 'Mag-export ng backup para sa paglipat ng device',
    myanmar: 'စက်ပြောင်းရန်အတွက် အရန်ဖိုင်ထုတ်ပါ',
  );
  String get exportBackup => _pick(
    japanese: 'バックアップを書き出す',
    english: 'Export backup',
    simplifiedChinese: '导出备份',
    traditionalChinese: '匯出備份',
    vietnamese: 'Xuất bản sao lưu',
    indonesian: 'Ekspor cadangan',
    filipino: 'I-export ang backup',
    myanmar: 'အရန်ဖိုင်ထုတ်မည်',
  );
  String get backupContents => _pick(
    japanese: 'バックアップ内容',
    english: 'Backup contents',
    simplifiedChinese: '备份内容',
    traditionalChinese: '備份內容',
    vietnamese: 'Nội dung sao lưu',
    indonesian: 'Isi cadangan',
    filipino: 'Nilalaman ng backup',
    myanmar: 'အရန်ဖိုင်အကြောင်းအရာ',
  );
  String get backupSensitiveDataNotice => _pick(
    japanese: 'バックアップには会社情報、住所、電話番号、見積、単価、履歴などが含まれます。保存先や共有先の管理にご注意ください。',
    english:
        'The backup contains company information, addresses, phone numbers, estimates, prices and history. Please manage where you save or share it carefully.',
    simplifiedChinese: '备份包含公司信息、地址、电话号码、估算、单价和历史记录等。请妥善管理保存位置和共享对象。',
    traditionalChinese: '備份包含公司資訊、地址、電話號碼、估價、單價和紀錄等。請妥善管理儲存位置和分享對象。',
    vietnamese:
        'Bản sao lưu chứa thông tin công ty, địa chỉ, số điện thoại, dự toán, đơn giá và lịch sử. Hãy quản lý cẩn thận nơi lưu hoặc chia sẻ.',
    indonesian:
        'Cadangan berisi informasi perusahaan, alamat, nomor telepon, estimasi, harga, dan riwayat. Kelola lokasi penyimpanan dan tujuan berbagi dengan hati-hati.',
    filipino:
        'Kasama sa backup ang impormasyon ng kumpanya, address, numero ng telepono, estimate, presyo, at history. Ingatan ang pagpili ng pagse-save at pagbabahagian.',
    myanmar:
        'အရန်ဖိုင်တွင် ကုမ္ပဏီအချက်အလက်၊ လိပ်စာ၊ ဖုန်းနံပါတ်၊ ခန့်မှန်းချက်၊ ဈေးနှုန်းနှင့် မှတ်တမ်းများ ပါဝင်သည်။ သိမ်းဆည်းရာနှင့် မျှဝေရာကို သေချာစွာ စီမံပါ။',
  );
  String backupEstimateCount(int count) => _pick(
    japanese: '見積：$count件',
    english: 'Estimates: $count',
    simplifiedChinese: '估算：$count项',
    traditionalChinese: '估價：$count筆',
    vietnamese: 'Dự toán: $count',
    indonesian: 'Estimasi: $count',
    filipino: 'Mga estimate: $count',
    myanmar: 'ခန့်မှန်းချက်: $count',
  );
  String backupUnitPriceCount(int count) => _pick(
    japanese: '単価マスタ：$count件',
    english: 'Unit-price master: $count',
    simplifiedChinese: '单价主数据：$count项',
    traditionalChinese: '單價主檔：$count筆',
    vietnamese: 'Danh mục đơn giá: $count',
    indonesian: 'Master harga satuan: $count',
    filipino: 'Unit-price master: $count',
    myanmar: 'ယူနစ်ဈေးစာရင်း: $count',
  );
  String backupHistoryCount(int count) => _pick(
    japanese: '計算履歴：$count件',
    english: 'Calculation history: $count',
    simplifiedChinese: '计算历史：$count项',
    traditionalChinese: '計算紀錄：$count筆',
    vietnamese: 'Lịch sử tính toán: $count',
    indonesian: 'Riwayat perhitungan: $count',
    filipino: 'Calculation history: $count',
    myanmar: 'တွက်ချက်မှုမှတ်တမ်း: $count',
  );
  String backupProductivityCount(int count) => _pick(
    japanese: '歩掛実績：$count件',
    english: 'Productivity records: $count',
    simplifiedChinese: '生产率记录：$count项',
    traditionalChinese: '生產率紀錄：$count筆',
    vietnamese: 'Dữ liệu năng suất: $count',
    indonesian: 'Catatan produktivitas: $count',
    filipino: 'Productivity records: $count',
    myanmar: 'ထုတ်လုပ်မှုမှတ်တမ်း: $count',
  );
  String get backupGenerationFailed => _pick(
    japanese: 'バックアップを作成できませんでした',
    english: 'Could not create the backup.',
    simplifiedChinese: '无法创建备份',
    traditionalChinese: '無法建立備份',
    vietnamese: 'Không thể tạo bản sao lưu.',
    indonesian: 'Cadangan tidak dapat dibuat.',
    filipino: 'Hindi nagawa ang backup.',
    myanmar: 'အရန်ဖိုင်ကို မဖန်တီးနိုင်ပါ။',
  );
  String get backupShareFailed => _pick(
    japanese: 'バックアップを共有できませんでした',
    english: 'Could not share the backup.',
    simplifiedChinese: '无法共享备份',
    traditionalChinese: '無法分享備份',
    vietnamese: 'Không thể chia sẻ bản sao lưu.',
    indonesian: 'Cadangan tidak dapat dibagikan.',
    filipino: 'Hindi maibahagi ang backup.',
    myanmar: 'အရန်ဖိုင်ကို မမျှဝေနိုင်ပါ။',
  );
  String get backupShareSubject => _pick(
    japanese: '現場電卓 データバックアップ',
    english: 'GenbaCalc data backup',
    simplifiedChinese: '现场计算器数据备份',
    traditionalChinese: '現場計算機資料備份',
    vietnamese: 'Sao lưu dữ liệu GenbaCalc',
    indonesian: 'Cadangan data GenbaCalc',
    filipino: 'Backup ng data ng GenbaCalc',
    myanmar: 'GenbaCalc ဒေတာအရန်ဖိုင်',
  );
  String get retry => _pick(
    japanese: '再試行',
    english: 'Retry',
    simplifiedChinese: '重试',
    traditionalChinese: '重試',
    vietnamese: 'Thử lại',
    indonesian: 'Coba lagi',
    filipino: 'Subukan muli',
    myanmar: 'ထပ်မံကြိုးစားမည်',
  );
  String get help => _pick(
    japanese: 'ヘルプ',
    english: 'Help',
    simplifiedChinese: '帮助',
    traditionalChinese: '說明',
  );
  String get helpIntroTitle => _pick(
    japanese: '現場計算と見積を安全に使う',
    english: 'Use site calculations and estimates safely',
    simplifiedChinese: '安全使用现场计算与估算',
    traditionalChinese: '安全使用現場計算與估算',
    vietnamese: 'Sử dụng phép tính và dự toán công trường an toàn',
    indonesian: 'Gunakan perhitungan dan estimasi lapangan dengan aman',
    filipino: 'Ligtas na gamitin ang kalkulasyon at estimasyon sa site',
    myanmar:
        'လုပ်ငန်းခွင်တွက်ချက်မှုနှင့် ခန့်မှန်းချက်များကို လုံခြုံစွာ အသုံးပြုပါ',
  );
  String get helpIntroBody => _pick(
    japanese: '関数電卓、便利計算、インスタント見積、帳票出力の現在の使い方を確認できます。',
    english:
        'Review the current use of the scientific calculator, practical calculators, instant estimates and document output.',
    simplifiedChinese: '查看科学计算器、实用计算、即时估算和文档输出的当前使用方法。',
    traditionalChinese: '查看科學計算機、實用計算、即時估算和文件輸出的目前使用方式。',
    vietnamese:
        'Xem cách sử dụng hiện tại của máy tính khoa học, các phép tính tiện ích, dự toán nhanh và xuất tài liệu.',
    indonesian:
        'Lihat cara penggunaan kalkulator ilmiah, perhitungan praktis, estimasi instan, dan keluaran dokumen.',
    filipino:
        'Tingnan ang kasalukuyang paggamit ng scientific calculator, praktikal na kalkulasyon, instant estimate, at paglabas ng dokumento.',
    myanmar:
        'သိပ္ပံဂဏန်းပေါင်းစက်၊ အသုံးဝင်သောတွက်ချက်မှုများ၊ ချက်ချင်းခန့်မှန်းချက်နှင့် စာရွက်စာတမ်းထုတ်ပေးမှုတို့၏ လက်ရှိအသုံးပြုပုံကို ကြည့်နိုင်သည်။',
  );
  String get helpCalculatorTitle => _pick(
    japanese: '電卓の基本操作',
    english: 'Calculator basics',
    simplifiedChinese: '计算器基本操作',
    traditionalChinese: '計算機基本操作',
    vietnamese: 'Các thao tác cơ bản của máy tính',
    indonesian: 'Operasi dasar kalkulator',
    filipino: 'Mga pangunahing operasyon ng calculator',
    myanmar: 'ဂဏန်းပေါင်းစက်၏ အခြေခံလုပ်ဆောင်ချက်များ',
  );
  String get helpCalculatorBody => _pick(
    japanese:
        '「…」で左メニュー、長押しまたはダブルタップで関数一覧を開きます。通常数値は小数点と先頭のマイナスを除いて20桁まで入力できます。長い式は自動縮小・複数行表示され、3行以上は式部分を縦にスクロールできます。\n\n設定の「ボタン設定」でタップ音と軽いバイブレーションを個別に切り替えられます。端末の消音・音量設定が優先されます。現在のバージョンは縦画面で使用します。',
    english:
        'Tap “…” for the left menu, or long-press or double-tap it for the function list. Regular numbers accept up to 20 digits, excluding the decimal point and a leading minus sign. Long expressions shrink and wrap automatically; from the third line, scroll the expression area vertically.\n\nIn Button settings, tap sound and light vibration can be switched independently. Device mute and volume settings take priority. The current version is used in portrait orientation.',
    simplifiedChinese:
        '点击“…”打开左侧菜单，长按或双击可打开函数列表。普通数字最多可输入20位，小数点和开头的负号不计入位数。长算式会自动缩小并换行；从第3行起可在算式区域纵向滚动。\n\n可在“按钮设置”中分别切换点击音和轻微振动。设备的静音和音量设置优先。当前版本使用竖屏。',
    traditionalChinese:
        '點按「…」開啟側邊選單，長按或點按兩下可開啟函數列表。一般數字最多可輸入20位，小數點和開頭負號不計入位數。長算式會自動縮小並換行；從第3行起可在算式區域垂直捲動。\n\n可在「按鈕設定」中分別切換點按音效和輕微震動。裝置的靜音和音量設定優先。目前版本使用直向畫面。',
    vietnamese:
        'Nhấn “…” để mở menu bên trái; nhấn giữ hoặc nhấn đúp để mở danh sách hàm. Số thông thường cho phép tối đa 20 chữ số, không tính dấu thập phân và dấu trừ ở đầu. Biểu thức dài sẽ tự thu nhỏ và xuống dòng; từ dòng thứ ba, có thể cuộn dọc phần biểu thức.\n\nTrong Cài đặt nút, có thể bật/tắt riêng âm thanh và rung nhẹ. Cài đặt im lặng và âm lượng của thiết bị được ưu tiên. Phiên bản hiện tại dùng màn hình dọc.',
    indonesian:
        'Ketuk “…” untuk membuka menu sebelah kiri; tekan lama atau ketuk dua kali untuk membuka daftar fungsi. Angka biasa menerima hingga 20 digit, tidak termasuk tanda desimal dan minus di awal. Ekspresi panjang mengecil dan berpindah baris otomatis; mulai baris ketiga, area ekspresi dapat digulir vertikal.\n\nDi Pengaturan tombol, suara ketukan dan getaran ringan dapat diatur terpisah. Pengaturan senyap dan volume perangkat diprioritaskan. Versi saat ini digunakan dalam orientasi potret.',
    filipino:
        'I-tap ang “…” para buksan ang kaliwang menu; i-long-press o i-double-tap para buksan ang listahan ng function. Hanggang 20 digit ang regular na numero, hindi kasama ang decimal point at unang minus sign. Awtomatikong lumiliit at lumilipat ng linya ang mahabang expression; mula ikatlong linya, maaaring i-scroll nang patayo ang expression area.\n\nSa Mga setting ng button, magkahiwalay na makokontrol ang tap sound at mahinang vibration. Masusunod ang mute at volume ng device. Portrait orientation ang gamit ng kasalukuyang bersyon.',
    myanmar:
        '“…” ကိုနှိပ်၍ ဘယ်ဘက်မီနူးကို ဖွင့်နိုင်ပြီး၊ ဖိထားခြင်း သို့မဟုတ် နှစ်ချက်နှိပ်ခြင်းဖြင့် function စာရင်းကို ဖွင့်နိုင်သည်။ ပုံမှန်ကိန်းများတွင် ဒဿမအမှတ်နှင့် ရှေ့ဆုံးအနုတ်လက္ခဏာမပါဘဲ ဂဏန်း ၂၀ လုံးအထိ ထည့်နိုင်သည်။ ရှည်သောပုံသေနည်းများသည် အလိုအလျောက်သေးပြီး စာကြောင်းခွဲပြမည်။ တတိယစာကြောင်းမှစ၍ ပုံသေနည်းနေရာကို ဒေါင်လိုက်ရွှေ့ကြည့်နိုင်သည်။\n\nခလုတ်ဆက်တင်တွင် နှိပ်သံနှင့် ပေါ့ပါးသောတုန်ခါမှုကို သီးခြားဖွင့်ပိတ်နိုင်သည်။ စက်၏အသံပိတ်နှင့် အသံအတိုးအကျယ်ဆက်တင်ကို ဦးစားပေးသည်။ လက်ရှိဗားရှင်းကို ဒေါင်လိုက်မျက်နှာပြင်ဖြင့် အသုံးပြုသည်။',
  );
  String get helpFractionTitle => _pick(
    japanese: '分数の入力と表示',
    english: 'Fractions',
    simplifiedChinese: '分数输入与显示',
    traditionalChinese: '分數輸入與顯示',
    vietnamese: 'Nhập và hiển thị phân số',
    indonesian: 'Input dan tampilan pecahan',
    filipino: 'Pag-input at display ng fraction',
    myanmar: 'အပိုင်းကိန်းထည့်သွင်းခြင်းနှင့် ပြသခြင်း',
  );
  String get helpFractionBody => _pick(
    japanese:
        '「a/b」で分数枠を挿入します。分子・分母は小数を含めて入力でき、小数点と先頭のマイナスを除いてそれぞれ20桁までです。入力中の末尾0は保持され、分母が数値として0の分数は確定できません。\n\n分数化できる結果では「a/b」と「=」がオレンジになり、仮分数・帯分数・小数を切り替えられます。見積数量へ送る場合は表示形式にかかわらず小数値を使用します。',
    english:
        'Tap “a/b” to insert a fraction. Numerators and denominators may contain decimals and accept up to 20 digits each, excluding the decimal point and a leading minus sign. Trailing zeros are preserved while editing, and a denominator whose numeric value is zero cannot be confirmed.\n\nFor results that can be shown as a fraction, “a/b” and “=” turn orange and cycle through improper fraction, mixed fraction and decimal. Sending a result as an estimate quantity always uses its decimal value.',
    simplifiedChinese:
        '点击“a/b”插入分数框。分子和分母可输入小数，各最多20位，小数点和开头负号不计入位数。输入中的末尾0会保留，数值为0的分母不能确认。\n\n结果可显示为分数时，“a/b”和“=”会变为橙色，可在假分数、带分数和小数之间切换。发送到估算数量时始终使用小数值。',
    traditionalChinese:
        '點按「a/b」插入分數框。分子和分母可輸入小數，各最多20位，小數點和開頭負號不計入位數。輸入中的尾端0會保留，數值為0的分母無法確認。\n\n結果可顯示為分數時，「a/b」和「=」會變成橙色，可在假分數、帶分數和小數之間切換。傳送到估算數量時一律使用小數值。',
    vietnamese:
        'Nhấn “a/b” để chèn khung phân số. Tử số và mẫu số có thể chứa số thập phân, mỗi phần tối đa 20 chữ số, không tính dấu thập phân và dấu trừ ở đầu. Số 0 ở cuối được giữ khi nhập và không thể xác nhận mẫu số có giá trị bằng 0.\n\nKhi kết quả có thể hiển thị dưới dạng phân số, “a/b” và “=” chuyển sang màu cam để đổi giữa phân số không đúng, hỗn số và số thập phân. Khi gửi tới số lượng dự toán, luôn dùng giá trị thập phân.',
    indonesian:
        'Ketuk “a/b” untuk menyisipkan pecahan. Pembilang dan penyebut dapat berisi desimal, masing-masing hingga 20 digit, tidak termasuk tanda desimal dan minus di awal. Nol di akhir dipertahankan saat mengedit, dan penyebut bernilai nol tidak dapat dikonfirmasi.\n\nJika hasil dapat ditampilkan sebagai pecahan, “a/b” dan “=” menjadi oranye untuk beralih antara pecahan tidak wajar, pecahan campuran, dan desimal. Saat dikirim sebagai kuantitas estimasi, nilai desimal selalu digunakan.',
    filipino:
        'I-tap ang “a/b” para maglagay ng fraction. Maaaring may decimal ang numerator at denominator at hanggang 20 digit bawat isa, hindi kasama ang decimal point at unang minus sign. Pinananatili ang trailing zero habang nag-e-edit, at hindi maaaring kumpirmahin ang denominator na zero ang halaga.\n\nKapag maaaring gawing fraction ang resulta, nagiging orange ang “a/b” at “=” upang magpalit sa improper fraction, mixed fraction, at decimal. Decimal value ang palaging ginagamit kapag ipinadala bilang estimate quantity.',
    myanmar:
        '“a/b” ကိုနှိပ်၍ အပိုင်းကိန်းဘောင်ထည့်ပါ။ ပိုင်းဝေနှင့် ပိုင်းခြေတွင် ဒဿမထည့်နိုင်ပြီး ဒဿမအမှတ်နှင့် ရှေ့ဆုံးအနုတ်လက္ခဏာမပါဘဲ တစ်ခုစီ ဂဏန်း ၂၀ လုံးအထိ ထည့်နိုင်သည်။ ထည့်သွင်းနေစဉ် နောက်ဆုံးသုညများကို ထိန်းထားပြီး တန်ဖိုးသုညဖြစ်သော ပိုင်းခြေကို အတည်မပြုနိုင်ပါ။\n\nအပိုင်းကိန်းအဖြစ်ပြနိုင်သောရလဒ်တွင် “a/b” နှင့် “=” သည် လိမ္မော်ရောင်ဖြစ်ပြီး မသင့်အပိုင်းကိန်း၊ ရောနှောအပိုင်းကိန်းနှင့် ဒဿမတို့ကို ပြောင်းနိုင်သည်။ ခန့်မှန်းအရေအတွက်သို့ပို့ရာတွင် ဒဿမတန်ဖိုးကို အမြဲအသုံးပြုသည်။',
  );
  String get helpHistoryTitle => _pick(
    japanese: '計算履歴',
    english: 'Calculation history',
    simplifiedChinese: '计算历史',
    traditionalChinese: '計算歷史',
    vietnamese: 'Lịch sử tính toán',
    indonesian: 'Riwayat perhitungan',
    filipino: 'History ng kalkulasyon',
    myanmar: 'တွက်ချက်မှုမှတ်တမ်း',
  );
  String get helpHistoryBody => _pick(
    japanese:
        '電卓上部には無料版で3行、広告なし版・完全版で5行を表示します。履歴メニューからコピー、共有、編集、削除、スター、見積への送信ができます。履歴領域を長押しすると、検索・並べ替え・全件確認ができる画面を開きます。',
    english:
        'The calculator shows three history rows in the free version and five in the ad-free and full versions. The history menu supports copy, share, edit, delete, star and send to estimate. Long-press the history area for search, sorting and the complete list.',
    simplifiedChinese:
        '计算器顶部在免费版显示3行历史，在无广告版和完整版显示5行。历史菜单支持复制、分享、编辑、删除、加星和发送到估算。长按历史区域可搜索、排序并查看全部记录。',
    traditionalChinese:
        '計算機頂端在免費版顯示3行紀錄，在無廣告版和完整版顯示5行。紀錄選單支援複製、分享、編輯、刪除、加星號和傳送到估算。長按紀錄區域可搜尋、排序並查看全部紀錄。',
    vietnamese:
        'Máy tính hiển thị 3 dòng lịch sử ở bản miễn phí và 5 dòng ở bản không quảng cáo hoặc bản đầy đủ. Menu lịch sử cho phép sao chép, chia sẻ, chỉnh sửa, xóa, đánh dấu sao và gửi tới dự toán. Nhấn giữ vùng lịch sử để tìm kiếm, sắp xếp và xem toàn bộ.',
    indonesian:
        'Kalkulator menampilkan 3 baris riwayat pada versi gratis dan 5 baris pada versi bebas iklan atau lengkap. Menu riwayat mendukung salin, bagikan, edit, hapus, bintang, dan kirim ke estimasi. Tekan lama area riwayat untuk mencari, mengurutkan, dan melihat semua.',
    filipino:
        'Tatlong history row ang ipinapakita sa libreng bersyon at lima sa ad-free at full na bersyon. Sa history menu maaaring kumopya, mag-share, mag-edit, mag-delete, mag-star, at magpadala sa estimate. I-long-press ang history area para maghanap, mag-sort, at makita ang lahat.',
    myanmar:
        'အခမဲ့ဗားရှင်းတွင် မှတ်တမ်း ၃ ကြောင်း၊ ကြော်ငြာမဲ့နှင့် အပြည့်အစုံဗားရှင်းတွင် ၅ ကြောင်း ပြသသည်။ မှတ်တမ်းမီနူးမှ ကူးယူ၊ မျှဝေ၊ ပြင်ဆင်၊ ဖျက်၊ ကြယ်တပ်နှင့် ခန့်မှန်းချက်သို့ ပို့နိုင်သည်။ မှတ်တမ်းနေရာကို ဖိထား၍ ရှာဖွေ၊ စီစဉ်ပြီး အားလုံးကြည့်နိုင်သည်။',
  );
  String get helpToolsTitle => _pick(
    japanese: '単位変換・便利計算',
    english: 'Unit conversion and practical calculators',
    simplifiedChinese: '单位换算与实用计算',
    traditionalChinese: '單位換算與實用計算',
    vietnamese: 'Chuyển đổi đơn vị và phép tính tiện ích',
    indonesian: 'Konversi satuan dan perhitungan praktis',
    filipino: 'Unit conversion at praktikal na kalkulasyon',
    myanmar: 'ယူနစ်ပြောင်းလဲခြင်းနှင့် အသုံးဝင်သောတွက်ချက်မှုများ',
  );
  String get helpToolsBody => _pick(
    japanese:
        '単位変換に加え、土量、比重・重量、勾配・法面、三角形・四角形・多角形の面積、対比、歩掛・生産性などを利用できます。初期値や候補値は参考値です。図面、仕様、土質、施工条件に合わせて入力値と係数を確認してください。',
    english:
        'Use unit conversion plus earthwork, density and weight, slope, triangle/quadrilateral/polygon area, ratio, labor and productivity calculators. Defaults and suggestions are references; verify inputs and factors against drawings, specifications, soil and site conditions.',
    simplifiedChinese:
        '可使用单位换算，以及土方、密度与重量、坡度、三角形/四边形/多边形面积、比例、工时与生产率等计算。默认值和候选值仅供参考，请根据图纸、规格、土质和施工条件确认输入值与系数。',
    traditionalChinese:
        '可使用單位換算，以及土方、密度與重量、坡度、三角形／四邊形／多邊形面積、比例、工時與生產率等計算。預設值和候選值僅供參考，請依圖面、規格、土質和施工條件確認輸入值與係數。',
    vietnamese:
        'Có thể dùng chuyển đổi đơn vị cùng các phép tính đất, tỷ trọng và trọng lượng, độ dốc, diện tích tam giác/tứ giác/đa giác, tỷ lệ, định mức lao động và năng suất. Giá trị mặc định và gợi ý chỉ để tham khảo; hãy kiểm tra theo bản vẽ, thông số, đất và điều kiện thi công.',
    indonesian:
        'Gunakan konversi satuan serta kalkulator pekerjaan tanah, kepadatan dan berat, kemiringan, luas segitiga/segi empat/poligon, rasio, tenaga kerja, dan produktivitas. Nilai awal dan saran adalah referensi; periksa sesuai gambar, spesifikasi, tanah, dan kondisi lapangan.',
    filipino:
        'Gamitin ang unit conversion at mga kalkulasyon para sa earthwork, density at timbang, slope, area ng triangle/quadrilateral/polygon, ratio, labor, at productivity. Reference lamang ang default at mungkahing value; beripikahin ayon sa drawing, specification, lupa, at site condition.',
    myanmar:
        'ယူနစ်ပြောင်းလဲခြင်းအပြင် မြေထုထည်၊ သိပ်သည်းဆနှင့်အလေးချိန်၊ လျှောစောက်၊ တြိဂံ/စတုဂံ/ဗဟုဂံဧရိယာ၊ အချိုး၊ လုပ်အားနှင့်ထုတ်လုပ်မှုတွက်ချက်မှုများကို အသုံးပြုနိုင်သည်။ မူလနှင့်အကြံပြုတန်ဖိုးများသည် ကိုးကားရန်သာဖြစ်ပြီး ပုံဆွဲ၊ သတ်မှတ်ချက်၊ မြေအမျိုးအစားနှင့် လုပ်ငန်းခွင်အခြေအနေအတိုင်း စစ်ဆေးပါ။',
  );
  String get helpEstimateTitle => instantEstimate;
  String get helpEstimateBody => _pick(
    japanese:
        '見積名・現場名、作成日、但し書き、有効期限、工期、支払条件、備考を保存できます。明細は記号と施工場所を1対1でまとめ、名称、仕様、数量、単位、単価、金額、摘要を管理します。工種はアプリ内分類と単価マスタ用で、正式帳票には出力しません。\n\n単価マスタから名称・仕様・単位・単価・工種を復元できます。見積専用の小数桁数と丸め方法は関数電卓設定とは独立し、行金額、小計、消費税、税込合計へ反映されます。',
    english:
        'Save the estimate/site name, date, subject note, validity, construction period, payment terms and remarks. Items are grouped by a one-to-one symbol and construction location and hold name, specification, quantity, unit, unit price, amount and note. Work type is for internal classification and the unit-price master and is not printed on formal documents.\n\nThe unit-price master restores name, specification, unit, price and work type. Estimate decimal places and rounding are independent from calculator settings and apply to line amounts, subtotals, tax and grand total.',
    simplifiedChinese:
        '可保存估算名/现场名、创建日、但书、有效期、工期、付款条件和备注。明细按一一对应的符号与施工位置分组，并管理名称、规格、数量、单位、单价、金额和摘要。工种仅用于应用内分类和单价主数据，不输出到正式文档。\n\n可从单价主数据恢复名称、规格、单位、单价和工种。估算专用小数位数与舍入方式独立于计算器设置，并用于行金额、小计、税额和含税总额。',
    traditionalChinese:
        '可儲存估算名／現場名、建立日、但書、有效期限、工期、付款條件和備註。明細依一對一的記號與施工位置分組，並管理名稱、規格、數量、單位、單價、金額和摘要。工種僅用於應用程式內分類與單價主檔，不輸出至正式文件。\n\n可從單價主檔還原名稱、規格、單位、單價和工種。估算專用小數位數與捨入方式獨立於計算機設定，並套用於各行金額、小計、稅額和含稅總額。',
    vietnamese:
        'Có thể lưu tên dự toán/công trường, ngày tạo, nội dung, thời hạn, thời gian thi công, điều khoản thanh toán và ghi chú. Chi tiết được nhóm theo ký hiệu và vị trí thi công một-một, gồm tên, quy cách, số lượng, đơn vị, đơn giá, thành tiền và ghi chú. Loại công việc chỉ dùng để phân loại nội bộ và danh mục đơn giá, không in trên chứng từ chính thức.\n\nDanh mục đơn giá khôi phục tên, quy cách, đơn vị, đơn giá và loại công việc. Số lẻ và cách làm tròn của dự toán độc lập với máy tính và áp dụng cho thành tiền, tạm tính, thuế và tổng cộng.',
    indonesian:
        'Simpan nama estimasi/lokasi, tanggal, catatan subjek, masa berlaku, periode konstruksi, syarat pembayaran, dan catatan. Item dikelompokkan menurut simbol dan lokasi konstruksi satu-ke-satu serta menyimpan nama, spesifikasi, kuantitas, satuan, harga satuan, jumlah, dan catatan. Jenis pekerjaan hanya untuk klasifikasi internal dan master harga, tidak dicetak pada dokumen resmi.\n\nMaster harga memulihkan nama, spesifikasi, satuan, harga, dan jenis pekerjaan. Desimal serta pembulatan estimasi terpisah dari kalkulator dan diterapkan ke jumlah baris, subtotal, pajak, dan total.',
    filipino:
        'Maaaring i-save ang estimate/site name, petsa, subject note, validity, construction period, payment terms, at remarks. Pinapangkat ang item sa one-to-one na simbolo at construction location, at may name, specification, quantity, unit, unit price, amount, at note. Internal classification at unit-price master lamang ang work type at hindi ito inilalabas sa formal document.\n\nMula sa unit-price master, maibabalik ang name, specification, unit, price, at work type. Hiwalay sa calculator ang decimal places at rounding ng estimate at ginagamit sa line amount, subtotal, tax, at grand total.',
    myanmar:
        'ခန့်မှန်း/လုပ်ငန်းခွင်အမည်၊ ဖန်တီးရက်၊ အကြောင်းအရာ၊ သက်တမ်း၊ ဆောက်လုပ်ချိန်၊ ငွေပေးချေမှုစည်းကမ်းနှင့် မှတ်ချက်ကို သိမ်းနိုင်သည်။ အချက်များကို သင်္ကေတနှင့် ဆောက်လုပ်ရာနေရာ တစ်ခုချင်းစီဖြင့် အုပ်စုဖွဲ့ပြီး အမည်၊ သတ်မှတ်ချက်၊ အရေအတွက်၊ ယူနစ်၊ ယူနစ်ဈေး၊ ငွေပမာဏနှင့် မှတ်ချက်ကို စီမံသည်။ အလုပ်အမျိုးအစားသည် အတွင်းပိုင်းခွဲခြားမှုနှင့် ယူနစ်ဈေးစာရင်းအတွက်သာဖြစ်ပြီး တရားဝင်စာရွက်တွင် မထုတ်ပါ။\n\nယူနစ်ဈေးစာရင်းမှ အမည်၊ သတ်မှတ်ချက်၊ ယူနစ်၊ ဈေးနှင့် အလုပ်အမျိုးအစားကို ပြန်ယူနိုင်သည်။ ခန့်မှန်းဒဿမနှင့် လုံးချခြင်းသည် ဂဏန်းပေါင်းစက်ဆက်တင်နှင့် သီးခြားဖြစ်ပြီး အတန်းငွေ၊ အုပ်စုငွေ၊ အခွန်နှင့် စုစုပေါင်းတွင် အသုံးပြုသည်။',
  );
  String get helpOutputTitle => _pick(
    japanese: '見積書の出力',
    english: 'Estimate output',
    simplifiedChinese: '估算文档输出',
    traditionalChinese: '估算文件輸出',
    vietnamese: 'Xuất báo giá',
    indonesian: 'Keluaran estimasi',
    filipino: 'Paglabas ng estimate',
    myanmar: 'ခန့်မှန်းစာရွက်ထုတ်ခြင်း',
  );
  String get helpOutputBody => _pick(
    japanese:
        '正式Excelは表紙と20行周期の内訳を出力します。正式PDFは同じ見積データとページ構成を使用し、保存・共有できます。印刷は最新の正式PDFをそのままOSの印刷画面へ渡します。Excel貼り付けコピーは加工用の表データです。\n\n自社情報は設定した順序と表示／非表示を反映し、帳票へ最大5項目を出力します。正式Excel・PDF・印刷では工種を表示しません。',
    english:
        'Formal Excel exports a cover and 20-row-cycle breakdown. Formal PDF uses the same estimate data and page structure and can be saved or shared. Print sends a newly generated formal PDF directly to the OS print dialog. Excel table copy is editable tabular data.\n\nCompany information follows its configured order and visibility, with up to five fields on documents. Work type is hidden from formal Excel, PDF and print.',
    simplifiedChinese:
        '正式Excel输出封面和按20行周期分页的明细。正式PDF使用相同的估算数据和页面结构，可保存或分享。打印会把最新生成的正式PDF直接交给系统打印界面。Excel表格复制用于后续编辑。\n\n自社信息按设定顺序和显示/隐藏状态输出，文档最多显示5项。正式Excel、PDF和打印不显示工种。',
    traditionalChinese:
        '正式Excel輸出封面和以20行週期分頁的明細。正式PDF使用相同的估算資料和頁面結構，可儲存或分享。列印會把最新產生的正式PDF直接交給系統列印畫面。Excel表格複製供後續編輯。\n\n自社資訊依設定順序和顯示／隱藏狀態輸出，文件最多顯示5項。正式Excel、PDF和列印不顯示工種。',
    vietnamese:
        'Excel chính thức xuất trang bìa và bảng chi tiết theo chu kỳ 20 dòng. PDF chính thức dùng cùng dữ liệu dự toán và cấu trúc trang, có thể lưu hoặc chia sẻ. In gửi PDF chính thức mới tạo trực tiếp tới hộp thoại in của hệ điều hành. Sao chép bảng Excel dùng cho chỉnh sửa.\n\nThông tin công ty tuân theo thứ tự và trạng thái hiển thị đã đặt, tối đa 5 mục trên chứng từ. Loại công việc không xuất hiện trong Excel, PDF và bản in chính thức.',
    indonesian:
        'Excel formal mengekspor sampul dan rincian dengan siklus 20 baris. PDF formal memakai data estimasi dan struktur halaman yang sama serta dapat disimpan atau dibagikan. Cetak mengirim PDF formal terbaru langsung ke dialog cetak OS. Salin tabel Excel adalah data untuk pengolahan.\n\nInformasi perusahaan mengikuti urutan dan visibilitas yang diatur, maksimal 5 bidang pada dokumen. Jenis pekerjaan tidak ditampilkan di Excel, PDF, dan cetak formal.',
    filipino:
        'Ang formal Excel ay may cover at breakdown na 20-row cycle. Parehong estimate data at page structure ang gamit ng formal PDF at maaari itong i-save o i-share. Ipinapadala ng Print ang bagong formal PDF sa OS print dialog. Ang Excel table copy ay data para sa pag-edit.\n\nSinusunod ng company information ang itinakdang order at visibility, hanggang 5 field sa dokumento. Hindi ipinapakita ang work type sa formal Excel, PDF, at print.',
    myanmar:
        'တရားဝင် Excel တွင် မျက်နှာဖုံးနှင့် အတန်း ၂၀ စက်ဝန်းအသေးစိတ်ကို ထုတ်ပေးသည်။ တရားဝင် PDF သည် တူညီသောခန့်မှန်းဒေတာနှင့် စာမျက်နှာပုံစံကို အသုံးပြုပြီး သိမ်းဆည်း သို့မဟုတ် မျှဝေနိုင်သည်။ ပုံနှိပ်ခြင်းသည် အသစ်ထုတ်သော တရားဝင် PDF ကို OS ပုံနှိပ်မျက်နှာပြင်သို့ တိုက်ရိုက်ပို့သည်။ Excel ဇယားကူးယူမှုသည် ပြင်ဆင်ရန်ဒေတာဖြစ်သည်။\n\nကုမ္ပဏီအချက်အလက်သည် သတ်မှတ်ထားသောအစီအစဉ်နှင့် ပြ/မပြကို လိုက်နာပြီး စာရွက်တွင် ၅ ခုအထိ ထုတ်သည်။ အလုပ်အမျိုးအစားကို တရားဝင် Excel၊ PDF နှင့် ပုံနှိပ်တွင် မပြပါ။',
  );
  String get helpRewardedAdsTitle => _pick(
    japanese: '動画広告と広告非表示プラン',
    english: 'Video ads and ad-free plans',
    simplifiedChinese: '视频广告与无广告方案',
    traditionalChinese: '影片廣告與無廣告方案',
    vietnamese: 'Quảng cáo video và gói không quảng cáo',
    indonesian: 'Iklan video dan paket bebas iklan',
    filipino: 'Video ads at ad-free plan',
    myanmar: 'ဗီဒီယိုကြော်ငြာနှင့် ကြော်ငြာမဲ့အစီအစဉ်',
  );
  String helpRewardedAdsBody(int maximumPerDay) => _pick(
    japanese:
        '無料版の動画広告は用途別の3グループです。①便利計算、②インスタント見積と単価マスタ、③正式PDF・正式Excel・印刷・Excel貼り付けコピー。同じグループでは端末の同じ日付中に1回だけで、全グループを利用した場合は最大$maximumPerDay回／日です。\n\n視聴完了後は同じグループをその日の間利用でき、端末のローカル日付が変わると再度対象になります。広告を途中で閉じた場合は解除されません。広告を取得・表示できない場合は機能の利用を妨げません。広告なし版と完全版ではバナー広告・動画広告を表示しません。',
    english:
        'The free version has three video-ad groups: (1) practical calculators, (2) instant estimates and the unit-price master, and (3) formal PDF, formal Excel, print and Excel table copy. Each group requests an ad only once per device-local calendar day, for at most $maximumPerDay ads per day when all groups are used.\n\nAfter completion, that group remains available for the day and becomes eligible again when the device-local date changes. Closing the ad early does not unlock it. If an ad cannot be loaded or shown, use of the feature is not blocked. The ad-free and full plans show neither banner nor video ads.',
    simplifiedChinese:
        '免费版的视频广告分为3组：①实用计算，②即时估算与单价主数据，③正式PDF、正式Excel、打印与Excel表格复制。同一组在设备本地同一日期内只需一次；使用全部组时每天最多$maximumPerDay次。\n\n完整观看后，该组当天可继续使用；设备本地日期变化后会再次成为对象。中途关闭广告不会解锁。广告无法加载或显示时不会阻止功能使用。无广告版和完整版均不显示横幅或视频广告。',
    traditionalChinese:
        '免費版的影片廣告分為3組：①實用計算，②即時估算與單價主檔，③正式PDF、正式Excel、列印與Excel表格複製。同一組在裝置本地同一日期內只需一次；使用全部組別時每天最多$maximumPerDay次。\n\n完整觀看後，該組當天可繼續使用；裝置本地日期變更後會再次成為對象。中途關閉廣告不會解鎖。廣告無法載入或顯示時不會阻止功能使用。無廣告版和完整版均不顯示橫幅或影片廣告。',
    vietnamese:
        'Bản miễn phí có 3 nhóm quảng cáo video: (1) phép tính tiện ích, (2) dự toán nhanh và danh mục đơn giá, (3) PDF chính thức, Excel chính thức, in và sao chép bảng Excel. Mỗi nhóm chỉ yêu cầu một lần trong cùng ngày theo ngày cục bộ của thiết bị, tối đa $maximumPerDay quảng cáo/ngày nếu dùng cả ba nhóm.\n\nSau khi xem xong, nhóm đó dùng được trong ngày và sẽ áp dụng lại khi ngày cục bộ của thiết bị thay đổi. Đóng quảng cáo sớm sẽ không mở khóa. Nếu không tải hoặc hiển thị được quảng cáo, tính năng vẫn được sử dụng. Gói không quảng cáo và gói đầy đủ không hiển thị quảng cáo banner hoặc video.',
    indonesian:
        'Versi gratis memiliki 3 grup iklan video: (1) perhitungan praktis, (2) estimasi instan dan master harga, (3) PDF formal, Excel formal, cetak, dan salin tabel Excel. Setiap grup hanya meminta iklan sekali pada tanggal lokal perangkat yang sama, maksimal $maximumPerDay iklan per hari bila semua grup digunakan.\n\nSetelah selesai ditonton, grup tersebut tersedia sepanjang hari dan berlaku lagi saat tanggal lokal perangkat berubah. Menutup iklan lebih awal tidak membuka akses. Jika iklan tidak dapat dimuat atau ditampilkan, fitur tetap dapat digunakan. Paket bebas iklan dan lengkap tidak menampilkan iklan banner maupun video.',
    filipino:
        'May 3 video-ad group ang libreng bersyon: (1) praktikal na kalkulasyon, (2) instant estimate at unit-price master, at (3) formal PDF, formal Excel, print, at Excel table copy. Isang beses lang humihingi ng ad ang bawat group sa parehong local date ng device, hanggang $maximumPerDay ad bawat araw kapag ginamit ang lahat.\n\nPagkatapos mapanood, magagamit ang group sa buong araw at magiging saklaw muli kapag nagbago ang local date ng device. Hindi nag-a-unlock ang maagang pagsara ng ad. Kung hindi ma-load o maipakita ang ad, hindi haharangin ang feature. Walang banner o video ad sa ad-free at full plan.',
    myanmar:
        'အခမဲ့ဗားရှင်းတွင် ဗီဒီယိုကြော်ငြာအုပ်စု ၃ ခုရှိသည်။ (၁) အသုံးဝင်သောတွက်ချက်မှုများ၊ (၂) ချက်ချင်းခန့်မှန်းချက်နှင့် ယူနစ်ဈေးစာရင်း၊ (၃) တရားဝင် PDF၊ တရားဝင် Excel၊ ပုံနှိပ်ခြင်းနှင့် Excel ဇယားကူးယူခြင်း။ အုပ်စုတစ်ခုစီသည် စက်၏တူညီသောဒေသရက်စွဲအတွင်း တစ်ကြိမ်သာ ကြော်ငြာတောင်းပြီး အုပ်စုအားလုံးသုံးပါက တစ်ရက်လျှင် အများဆုံး $maximumPerDay ကြိမ်ဖြစ်သည်။\n\nကြည့်ရှုပြီးနောက် ထိုအုပ်စုကို ထိုနေ့အတွင်း အသုံးပြုနိုင်ပြီး စက်၏ဒေသရက်စွဲပြောင်းလျှင် ပြန်လည်သက်ရောက်မည်။ ကြော်ငြာကို စောစီးစွာပိတ်လျှင် မဖွင့်ပေးပါ။ ကြော်ငြာမတင်နိုင် သို့မဟုတ် မပြနိုင်ပါက လုပ်ဆောင်ချက်အသုံးပြုမှုကို မတားဆီးပါ။ ကြော်ငြာမဲ့နှင့် အပြည့်အစုံအစီအစဉ်တွင် banner နှင့် video ကြော်ငြာမပြပါ။',
  );
  String get helpDataTitle => _pick(
    japanese: 'データの保存',
    english: 'Data storage',
    simplifiedChinese: '数据保存',
    traditionalChinese: '資料儲存',
    vietnamese: 'Lưu trữ dữ liệu',
    indonesian: 'Penyimpanan data',
    filipino: 'Pag-save ng data',
    myanmar: 'ဒေတာသိမ်းဆည်းမှု',
  );
  String get helpDataBody => _pick(
    japanese:
        '見積、単価マスタ、計算履歴、歩掛実績、自社情報、設定などは端末内へ保存されます。アプリを削除した場合や端末を初期化した場合は保存内容が失われることがあります。重要な帳票はExcelやPDFとして別途保存してください。',
    english:
        'Estimates, the unit-price master, calculation history, productivity records, company information and settings are stored on the device. Deleting the app or resetting the device may remove them. Save important documents separately as Excel or PDF.',
    simplifiedChinese:
        '估算、单价主数据、计算历史、生产率记录、自社信息和设置等保存在设备内。删除应用或初始化设备时可能丢失。请将重要文档另存为Excel或PDF。',
    traditionalChinese:
        '估算、單價主檔、計算紀錄、生產率紀錄、自社資訊和設定等儲存在裝置內。刪除應用程式或初始化裝置時可能遺失。請將重要文件另存為Excel或PDF。',
    vietnamese:
        'Dự toán, danh mục đơn giá, lịch sử tính toán, dữ liệu năng suất, thông tin công ty và cài đặt được lưu trên thiết bị. Xóa ứng dụng hoặc đặt lại thiết bị có thể làm mất dữ liệu. Hãy lưu riêng tài liệu quan trọng dưới dạng Excel hoặc PDF.',
    indonesian:
        'Estimasi, master harga, riwayat perhitungan, catatan produktivitas, informasi perusahaan, dan pengaturan disimpan di perangkat. Menghapus aplikasi atau mereset perangkat dapat menghilangkannya. Simpan dokumen penting secara terpisah sebagai Excel atau PDF.',
    filipino:
        'Naka-save sa device ang estimate, unit-price master, calculation history, productivity record, company information, at settings. Maaaring mawala ang mga ito kapag dinelete ang app o ni-reset ang device. I-save nang hiwalay bilang Excel o PDF ang mahalagang dokumento.',
    myanmar:
        'ခန့်မှန်းချက်၊ ယူနစ်ဈေးစာရင်း၊ တွက်ချက်မှုမှတ်တမ်း၊ ထုတ်လုပ်မှုမှတ်တမ်း၊ ကုမ္ပဏီအချက်အလက်နှင့် ဆက်တင်များကို စက်ထဲတွင် သိမ်းထားသည်။ အက်ပ်ဖျက်ခြင်း သို့မဟုတ် စက်ကို ပြန်လည်သတ်မှတ်ခြင်းဖြင့် ပျောက်ဆုံးနိုင်သည်။ အရေးကြီးစာရွက်များကို Excel သို့မဟုတ် PDF အဖြစ် သီးခြားသိမ်းပါ။',
  );
  String get helpBackupTitle => dataBackup;
  String get helpBackupBody => _pick(
    japanese:
        '機種変更前に、設定の「データのバックアップ」からバックアップを書き出し、FilesやiCloud Driveなどへ保存してください。ファイルには会社情報、見積、単価、計算履歴などが含まれるため、保存先と共有先を適切に管理してください。\n\n購入権利と広告の視聴状態はバックアップに含まれません。購入権利は新しい端末でApp Storeから復元してください。バックアップファイルを編集したり破損させたりしないでください。',
    english:
        'Before changing devices, export a backup from Data backup in Settings and save it to Files, iCloud Drive or another safe location. It contains company information, estimates, prices and calculation history, so manage its storage and sharing carefully.\n\nPurchase rights and ad-viewing status are not included. Restore purchases from the App Store on the new device. Do not edit or damage the backup file.',
    simplifiedChinese:
        '更换设备前，请从“设置”中的“数据备份”导出备份，并保存到“文件”、iCloud Drive或其他安全位置。文件包含公司信息、估算、单价和计算历史等，请妥善管理保存位置和共享对象。\n\n购买权益和广告观看状态不包含在备份中。请在新设备上通过App Store恢复购买。请勿编辑或损坏备份文件。',
    traditionalChinese:
        '更換裝置前，請從「設定」中的「資料備份」匯出備份，並儲存至「檔案」、iCloud Drive或其他安全位置。檔案包含公司資訊、估價、單價和計算紀錄等，請妥善管理儲存位置和分享對象。\n\n購買權益和廣告觀看狀態不包含在備份中。請在新裝置上透過App Store回復購買。請勿編輯或損壞備份檔案。',
    vietnamese:
        'Trước khi đổi thiết bị, hãy xuất bản sao lưu từ mục Sao lưu dữ liệu trong Cài đặt và lưu vào Files, iCloud Drive hoặc nơi an toàn khác. Tệp có thông tin công ty, dự toán, đơn giá và lịch sử tính toán, vì vậy hãy quản lý cẩn thận nơi lưu và chia sẻ.\n\nQuyền mua và trạng thái xem quảng cáo không được sao lưu. Hãy khôi phục giao dịch mua từ App Store trên thiết bị mới. Không chỉnh sửa hoặc làm hỏng tệp sao lưu.',
    indonesian:
        'Sebelum berganti perangkat, ekspor cadangan dari Cadangan data di Pengaturan dan simpan ke Files, iCloud Drive, atau lokasi aman lainnya. File berisi informasi perusahaan, estimasi, harga satuan, dan riwayat perhitungan, jadi kelola penyimpanan dan pembagiannya dengan hati-hati.\n\nHak pembelian dan status tontonan iklan tidak disertakan. Pulihkan pembelian dari App Store di perangkat baru. Jangan mengedit atau merusak file cadangan.',
    filipino:
        'Bago magpalit ng device, i-export ang backup mula sa Data backup sa Settings at i-save sa Files, iCloud Drive, o ibang ligtas na lokasyon. May kasama itong impormasyon ng kumpanya, estimate, presyo, at calculation history, kaya ingatan ang pag-save at pagbabahagi.\n\nHindi kasama ang purchase rights at ad-viewing status. I-restore ang purchases mula sa App Store sa bagong device. Huwag i-edit o sirain ang backup file.',
    myanmar:
        'စက်မပြောင်းမီ ဆက်တင်ရှိ ဒေတာအရန်သိမ်းခြင်းမှ အရန်ဖိုင်ထုတ်ပြီး Files၊ iCloud Drive သို့မဟုတ် လုံခြုံသောနေရာတွင် သိမ်းပါ။ ဖိုင်တွင် ကုမ္ပဏီအချက်အလက်၊ ခန့်မှန်းချက်၊ ဈေးနှုန်းနှင့် တွက်ချက်မှုမှတ်တမ်းများ ပါဝင်သဖြင့် သိမ်းဆည်းခြင်းနှင့် မျှဝေခြင်းကို သေချာစွာ စီမံပါ။\n\nဝယ်ယူခွင့်နှင့် ကြော်ငြာကြည့်ရှုမှုအခြေအနေ မပါဝင်ပါ။ စက်အသစ်တွင် App Store မှ ဝယ်ယူမှုကို ပြန်လည်ရယူပါ။ အရန်ဖိုင်ကို မပြင်ဆင်ပါနှင့်၊ မပျက်စီးစေပါနှင့်။',
  );
  String get disclaimerTitle => _pick(
    japanese: '免責・利用上の注意',
    english: 'Disclaimer and usage notes',
    simplifiedChinese: '免责声明与使用注意',
    traditionalChinese: '免責聲明與使用注意事項',
    vietnamese: 'Tuyên bố miễn trừ và lưu ý sử dụng',
    indonesian: 'Penafian dan catatan penggunaan',
    filipino: 'Disclaimer at mga paalala sa paggamit',
    myanmar: 'တာဝန်ကန့်သတ်ချက်နှင့် အသုံးပြုမှုသတိပြုရန်',
  );
  String get disclaimerSettingsSubtitle => _pick(
    japanese: '計算・見積・帳票を利用する前に確認してください',
    english: 'Review before using calculations, estimates or documents',
    simplifiedChinese: '使用计算、估算或文档前请确认',
    traditionalChinese: '使用計算、估算或文件前請確認',
    vietnamese: 'Hãy xem trước khi dùng phép tính, dự toán hoặc tài liệu',
    indonesian: 'Tinjau sebelum memakai perhitungan, estimasi, atau dokumen',
    filipino: 'Basahin bago gamitin ang kalkulasyon, estimate, o dokumento',
    myanmar:
        'တွက်ချက်မှု၊ ခန့်မှန်းချက် သို့မဟုတ် စာရွက်စာတမ်းမသုံးမီ ဖတ်ရှုပါ',
  );
  String get disclaimerBody => _pick(
    japanese:
        '本アプリの計算結果、数量、見積、換算結果、帳票内容は参考情報です。施工、発注、契約、申請、見積提出などを行う前に、利用者ご自身で入力値、設定、計算過程と出力内容を確認してください。\n\n法令、規格、設計図書、契約条件、メーカー仕様、現場条件などがある場合は、それらを優先してください。入力値や設定内容によって結果が変わるため、重要な用途では別の方法でも確認してください。\n\n本アプリの利用により生じた損害などについては、適用される法令で認められる範囲で責任を制限します。この案内は一般的な利用上の注意であり、すべての地域での法的な有効性を保証するものではありません。',
    english:
        'Calculations, quantities, estimates, conversions and document contents produced by this app are reference information. Before construction, ordering, contracting, applications or submitting an estimate, verify the inputs, settings, calculation process and output yourself.\n\nWhere laws, standards, drawings, contract terms, manufacturer specifications or site conditions apply, give them priority. Results vary with inputs and settings, so verify important uses by another method as well.\n\nLiability for loss arising from use of the app is limited to the extent permitted by applicable law. These are general usage notes and do not guarantee legal effectiveness in every jurisdiction.',
    simplifiedChinese:
        '本应用生成的计算结果、数量、估算、换算结果和文档内容仅供参考。在施工、订购、签订合同、申请或提交估算前，请自行确认输入值、设置、计算过程和输出内容。\n\n如有适用的法律法规、标准、设计文件、合同条件、制造商规格或现场条件，应优先遵循。结果会因输入和设置而变化，重要用途请同时通过其他方法核对。\n\n对于因使用本应用而产生的损失，责任将在适用法律允许的范围内予以限制。本说明为一般使用注意事项，不保证在所有地区具有完整法律效力。',
    traditionalChinese:
        '本應用程式產生的計算結果、數量、估算、換算結果和文件內容僅供參考。在施工、訂購、簽訂契約、申請或提交估算前，請自行確認輸入值、設定、計算過程和輸出內容。\n\n如有適用的法令、標準、設計文件、契約條件、製造商規格或現場條件，應優先遵循。結果會因輸入和設定而改變，重要用途請同時以其他方法核對。\n\n對於因使用本應用程式而產生的損失，責任將在適用法律允許的範圍內予以限制。本說明為一般使用注意事項，不保證在所有地區具有完整法律效力。',
    vietnamese:
        'Kết quả tính toán, số lượng, dự toán, chuyển đổi và nội dung tài liệu do ứng dụng tạo ra chỉ là thông tin tham khảo. Trước khi thi công, đặt hàng, ký hợp đồng, nộp hồ sơ hoặc gửi báo giá, hãy tự kiểm tra dữ liệu nhập, cài đặt, quá trình tính và nội dung xuất.\n\nNếu có luật, tiêu chuẩn, bản vẽ thiết kế, điều khoản hợp đồng, thông số nhà sản xuất hoặc điều kiện công trường, hãy ưu tiên các tài liệu đó. Kết quả thay đổi theo dữ liệu và cài đặt, vì vậy hãy kiểm tra các mục đích quan trọng bằng phương pháp khác.\n\nTrách nhiệm đối với thiệt hại phát sinh từ việc sử dụng ứng dụng được giới hạn trong phạm vi pháp luật áp dụng cho phép. Đây là lưu ý sử dụng chung và không bảo đảm hiệu lực pháp lý đầy đủ tại mọi khu vực.',
    indonesian:
        'Hasil perhitungan, kuantitas, estimasi, konversi, dan isi dokumen dari aplikasi ini merupakan informasi referensi. Sebelum konstruksi, pemesanan, kontrak, pengajuan, atau menyerahkan estimasi, periksa sendiri input, pengaturan, proses perhitungan, dan hasilnya.\n\nJika berlaku hukum, standar, gambar desain, ketentuan kontrak, spesifikasi produsen, atau kondisi lapangan, prioritaskan semuanya. Hasil berubah sesuai input dan pengaturan; untuk penggunaan penting, periksa juga dengan metode lain.\n\nTanggung jawab atas kerugian akibat penggunaan aplikasi dibatasi sejauh diizinkan oleh hukum yang berlaku. Ini adalah catatan penggunaan umum dan tidak menjamin keabsahan hukum penuh di setiap wilayah.',
    filipino:
        'Reference information lamang ang calculation result, quantity, estimate, conversion, at dokumentong ginagawa ng app. Bago ang construction, pag-order, kontrata, application, o pagsusumite ng estimate, sariling suriin ang input, setting, proseso ng pagkalkula, at output.\n\nKapag may naaangkop na batas, standard, design drawing, contract condition, manufacturer specification, o site condition, unahin ang mga iyon. Nagbabago ang resulta ayon sa input at setting, kaya beripikahin din sa ibang paraan ang mahahalagang gamit.\n\nAng pananagutan para sa pinsalang dulot ng paggamit ng app ay nililimitahan hanggang sa pinahihintulutan ng naaangkop na batas. Pangkalahatang paalala ito at hindi garantiya ng ganap na legal na bisa sa bawat hurisdiksiyon.',
    myanmar:
        'ဤအက်ပ်မှ ထုတ်ပေးသော တွက်ချက်ရလဒ်၊ အရေအတွက်၊ ခန့်မှန်းချက်၊ ပြောင်းလဲရလဒ်နှင့် စာရွက်စာတမ်းအကြောင်းအရာများသည် ကိုးကားရန်အချက်အလက်သာဖြစ်သည်။ ဆောက်လုပ်ခြင်း၊ မှာယူခြင်း၊ စာချုပ်ချုပ်ခြင်း၊ လျှောက်ထားခြင်း သို့မဟုတ် ခန့်မှန်းချက်တင်ပြခြင်းမပြုမီ ထည့်သွင်းတန်ဖိုး၊ ဆက်တင်၊ တွက်ချက်မှုလုပ်ငန်းစဉ်နှင့် ထုတ်ပေးချက်ကို ကိုယ်တိုင်စစ်ဆေးပါ။\n\nသက်ဆိုင်ရာဥပဒေ၊ စံနှုန်း၊ ဒီဇိုင်းစာရွက်၊ စာချုပ်စည်းကမ်း၊ ထုတ်လုပ်သူသတ်မှတ်ချက် သို့မဟုတ် လုပ်ငန်းခွင်အခြေအနေရှိပါက ၎င်းတို့ကို ဦးစားပေးပါ။ ထည့်သွင်းမှုနှင့်ဆက်တင်အလိုက် ရလဒ်ပြောင်းလဲနိုင်သဖြင့် အရေးကြီးအသုံးပြုမှုများကို အခြားနည်းဖြင့်လည်း စစ်ဆေးပါ။\n\nအက်ပ်အသုံးပြုမှုကြောင့် ဖြစ်ပေါ်သောဆုံးရှုံးမှုများအတွက် တာဝန်ကို သက်ဆိုင်ရာဥပဒေခွင့်ပြုသည့်အတိုင်းအတာအတွင်း ကန့်သတ်သည်။ ဤအချက်များသည် အထွေထွေအသုံးပြုမှုသတိပေးချက်သာဖြစ်ပြီး နေရာတိုင်းတွင် ဥပဒေအရ အပြည့်အဝထိရောက်မှုကို အာမခံခြင်းမဟုတ်ပါ။',
  );
  String get adFreePlan => _pick(
    japanese: '広告なし版（買い切り）',
    english: 'Ad-free (one-time purchase)',
    simplifiedChinese: '无广告版（一次性购买）',
    traditionalChinese: '無廣告版（一次性購買）',
  );
  String get fullPlan => _pick(
    japanese: '完全版（月額）',
    english: 'Full plan (monthly)',
    simplifiedChinese: '完整版（按月订阅）',
    traditionalChinese: '完整版（按月訂閱）',
  );
  String get convenientCalculations => _pick(
    japanese: '便利計算一覧',
    english: 'Convenient calculations',
    simplifiedChinese: '实用计算',
    traditionalChinese: '實用計算',
  );
  String get unitConversion => _pick(
    japanese: '単位変換',
    english: 'Unit conversion',
    simplifiedChinese: '单位换算',
    traditionalChinese: '單位換算',
  );
  String get instantEstimate => _pick(
    japanese: 'インスタント見積',
    english: 'Instant estimate',
    simplifiedChinese: '即时估算',
    traditionalChinese: '即時估算',
  );
  String get unitPriceMaster => _pick(
    japanese: '単価マスタ',
    english: 'Unit price master',
    simplifiedChinese: '单价资料库',
    traditionalChinese: '單價資料庫',
  );
  String get productivityMaster => _pick(
    japanese: '歩掛・生産性マスタ',
    english: '歩掛：BUGAKARI',
    simplifiedChinese: '步挂：BUGAKARI・生产率资料库',
    traditionalChinese: '步掛：BUGAKARI・生產率資料庫',
  );
  String get productivityTermTitle => _pick(
    japanese: '歩掛',
    english: '歩掛：BUGAKARI',
    simplifiedChinese: '步挂：BUGAKARI',
    traditionalChinese: '步掛：BUGAKARI',
  );
  String get productivityTermExplanation => _pick(
    japanese: '歩掛は、施工数量1単位あたりに必要な人工や作業量を表す建設実務用語です。',
    english:
        'Bugakari is a Japanese construction term for the labor required per unit of completed work. It is managed together with productivity records in this app.',
    simplifiedChinese:
        '“步挂（BUGAKARI）”是日本建筑行业术语，表示每单位完工数量所需的人工或工作量。本应用将其与生产率记录一并管理。',
    traditionalChinese:
        '「步掛（BUGAKARI）」是日本建築業術語，表示每單位完工數量所需的人工或工作量。本應用程式會與生產率紀錄一併管理。',
  );
  String get adArea => _pick(
    japanese: '広告エリア',
    english: 'Ad area',
    simplifiedChinese: '广告区域',
    traditionalChinese: '廣告區域',
  );

  String text(String japanese) {
    if (isJapanese) return japanese;
    if (isVietnamese) return vietnameseTranslations[japanese] ?? japanese;
    if (isIndonesian) return indonesianTranslations[japanese] ?? japanese;
    if (isFilipino) return filipinoTranslations[japanese] ?? japanese;
    if (isMyanmar) return myanmarTranslations[japanese] ?? japanese;
    if (isTraditionalChinese) {
      final translated = const <String, String>{
        '便利計算一覧': '實用計算',
        '土量計算': '土方計算',
        '比重・重量計算': '密度・重量計算',
        '勾配計算': '坡度計算',
        '面積計算': '面積計算',
        '5辺以上の面積計算': '五邊以上面積計算',
        '対比計算': '比例計算',
        '歩掛・生産性計算': '步掛・生產率計算',
        'クリア': '清除',
        'コピー': '複製',
        'カット': '剪下',
        'ペースト': '貼上',
        '消去': '清除',
        '共有': '分享',
        '編集': '編輯',
        '削除': '刪除',
        'スター': '星號',
        '関数一覧': '函數列表',
        '計算履歴': '計算歷史',
        '履歴の並び順': '歷史排序',
        '昇順': '升序',
        '降順': '降序',
        '計算式・解を検索': '搜尋算式和結果',
        'キャンセル': '取消',
        '見積へ送る': '傳送到估算',
        '設定': '設定',
        'ヘルプ': '說明',
        '単位変換': '單位換算',
        'インスタント見積': '即時估算',
        '単価マスタ': '單價資料庫',
        '掘削・搬出': '開挖・外運',
        '埋戻し': '回填',
        '盛土': '填土',
        '見積へ': '加入估算',
        '掘削・埋戻し・搬出土・運搬回数': '開挖、回填、外運土方及運輸次數',
        '材料と体積から重量を算出': '根據材料和體積計算重量',
        '高さ・水平距離・法長・角度を算出': '計算高度、水平距離、坡長和角度',
        '4辺と対角線から面積を算出': '根據四邊和對角線計算面積',
        '外周と対角線から三角形へ分割して自動合算': '根據外周和對角線分割成三角形並自動加總',
        '3つの値から残りの比率を算出': '根據三個數值計算其餘比例',
        '必要人工・必要日数・施工実績を計算': '計算所需人工、所需天數及施工實績',
        '長さ・面積・重量・勾配・土量などを変換': '換算長度、面積、重量、坡度及土方等單位',
        '体積': '體積',
        '同じ材料名が登録されています': '已儲存相同的材料名稱',
        '材料': '材料',
        '材料と体積から重量を計算します。初期の比重は目安のため、現場条件に合わせて変更できます。':
            '根據材料和體積計算重量。初始密度僅供參考，可依現場條件修改。',
        '材料を追加': '新增材料',
        '材料名': '材料名稱',
        '材料名を入力': '請輸入材料名稱',
        '比重': '密度',
        '登録材料を削除': '刪除已儲存材料',
        '見積明細へ追加': '加入估算明細',
        '見積へ追加しました': '已新增至估算',
        '計算結果': '計算結果',
        '追加': '新增',
        '重量を計算': '計算重量',
        'RCコンクリート': '鋼筋混凝土',
        '砕石': '碎石',
        'アスファルト': '瀝青',
        '砂': '砂',
        '山砂': '山砂',
        '改良土': '改良土',
        '残土': '剩餘土',
        '体積に0より大きい数値を入力してください': '請輸入大於0的體積',
        '比重に0より大きい数値を入力してください': '請輸入大於0的密度',
        '材料データを読み込めません': '無法讀取材料資料',
        '材料の比重が正しくありません': '材料密度無效',
        '掘削後のほぐし土量と運搬回数を算出します。': '計算開挖後的鬆散土方及運輸次數。',
        '構造物施工後に戻す土量を算出します。': '計算結構物施工後需要回填的土方。',
        '完成形状から必要な搬入土量を算出します。': '根據完成形狀計算所需運入土方。',
        '長さ': '長度',
        '幅': '寬度',
        '深さ': '深度',
        '掘削': '開挖',
        '掘削体積': '開挖體積',
        '地山掘削量': '原狀土開挖量',
        'ほぐし係数': '鬆散係數',
        '締固め係数': '壓實係數',
        'ほぐし土量（搬出土量）': '鬆散土方（外運土方）',
        '必要運搬回数': '所需運輸次數',
        '運搬車両': '運輸車輛',
        '積載容量': '裝載容量',
        '最大積載重量': '最大載重量',
        '通常車両': '一般車輛',
        'クローラータイプ': '履帶式車輛',
        'ユーザー登録車両': '使用者自訂車輛',
        '車両を追加': '新增車輛',
        '車両名': '車輛名稱',
        '軽トラック': '輕型卡車',
        '1tトラック': '1噸卡車',
        '2tダンプ': '2噸自卸車',
        '3tダンプ': '3噸自卸車',
        '4tダンプ': '4噸自卸車',
        '8tダンプ': '8噸自卸車',
        '10tダンプ': '10噸自卸車',
        '12tダンプ': '12噸自卸車',
        'セミトレーラー（土砂）': '半掛車（土砂）',
        'クローラーダンプ 0.5t': '履帶式自卸車 0.5噸',
        'クローラーダンプ 1t': '履帶式自卸車 1噸',
        'クローラーダンプ 2t': '履帶式自卸車 2噸',
        'クローラーダンプ 3t': '履帶式自卸車 3噸',
        'm³/回': '立方公尺/次',
        '回': '次',
        '回（切り上げ）': '次（無條件進位）',
        '端数切り上げ': '尾數無條件進位',
        '控除': '扣除',
        '控除する構造物体積（任意）': '扣除的結構物體積（選填）',
        '埋戻し対象体積': '回填目標體積',
        '必要土量': '所需土方',
        '埋戻し必要土': '所需回填土',
        '余剰土': '剩餘土方',
        '余剰土量': '剩餘土方量',
        '不足土': '土方不足',
        '不足土量': '土方不足量',
        '盛土高さ': '填土高度',
        '完成盛土量': '完成填土量',
        '締固めを考慮した必要土量': '考慮壓實後的所需土方',
        '必要搬入土量': '所需運入土方',
        '盛土必要土': '所需填土',
        '搬入土': '運入土方',
        '搬出土': '外運土方',
        '土砂運搬': '土方運輸',
        '法面あり': '有邊坡',
        '法面なし': '無邊坡',
        '法勾配（垂直1：水平）': '邊坡坡比（垂直1：水平）',
        '任意の水平比': '自訂水平比',
        '片側水平距離': '單側水平距離',
        '法面形状（参考）': '邊坡形狀（參考）',
        '完成形状': '完成形狀',
        '天端': '頂面',
        '天端の幅': '頂面寬度',
        '天端の長さ': '頂面長度',
        '底面': '底面',
        '搬入時のほぐし係数': '運入時的鬆散係數',
        '初期参考値 1.25': '初始參考值 1.25',
        '初期参考値 0.90': '初始參考值 0.90',
        '初期参考値 1.25（現場条件に合わせて変更可能）': '初始參考值1.25（可依現場條件修改）',
        '初期参考値 0.90（現場条件に合わせて変更可能）': '初始參考值0.90（可依現場條件修改）',
        '掘削体積 − 控除する構造物体積': '開挖體積－扣除的結構物體積',
        '地山掘削量 × ほぐし係数': '原狀土開挖量×鬆散係數',
        '埋戻し対象体積 ÷ 締固め係数': '回填目標體積÷壓實係數',
        '完成盛土量 ÷ 締固め係数': '完成填土量÷壓實係數',
        '必要土量 × ほぐし係数': '所需土方×鬆散係數',
        '※積載容量は車両・土質・積載条件により調整してください。': '※請依車輛、土質和裝載條件調整裝載容量。',
        '※候補は参考値です。設計図書や現場条件に合わせて確認・変更してください。': '※候選值僅供參考，請依設計文件和現場條件確認並修改。',
        '※ 土量変化率・積載容量・法勾配等は、土質・車両・現場条件・設計条件等により異なります。表示値は初期値・参考値として扱い、実際の条件に合わせて変更してください。':
            '※土方變化率、裝載容量和邊坡坡比會因土質、車輛、現場及設計條件而異。顯示值為初始參考值，請依實際條件修改。',
        '注意\n盛土高さが大きい場合は、地盤条件・法面安定・排水条件・設計図書・関係法令等を確認してください。':
            '注意\n填土較高時，請確認地基條件、邊坡穩定、排水條件、設計文件及相關法規。',
        '入力しない場合は0m³': '未輸入時以0立方公尺計算',
        '例：1 : 1.7 の場合は 1.7': '例：1 : 1.7時請輸入1.7',
        '任意入力': '自訂輸入',
        '0より大きい数値を入力': '請輸入大於0的數值',
        '0以上の数値を入力': '請輸入大於或等於0的數值',
        '0より大きい数値を入力してください': '請輸入大於0的數值',
        '数値を入力してください': '請輸入數值',
        '有効な数値を入力してください': '請輸入有效數值',
        '車両名を入力してください': '請輸入車輛名稱',
        '寸法・ほぐし係数・積載容量には0より大きい数値を入力してください': '尺寸、鬆散係數及裝載容量請輸入大於0的數值',
        '寸法・締固め係数には0より大きい数値を入力してください': '尺寸及壓實係數請輸入大於0的數值',
        '控除する構造物体積には0以上の数値を入力してください': '扣除的結構物體積請輸入大於或等於0的數值',
        '控除する構造物体積が掘削体積を超えています': '扣除的結構物體積超過開挖體積',
        '入力方法': '輸入方式',
        '入力項目（選択した2つから自動計算）': '輸入項目（根據選取的兩項自動計算）',
        '勾配': '坡度',
        '勾配・法面計算': '坡度・邊坡計算',
        '勾配（%）': '坡度（%）',
        '延長': '延伸長度',
        '水平距離': '水平距離',
        '水平距離（H）': '水平距離（H）',
        '法勾配': '邊坡坡比',
        '法長': '邊坡長度',
        '法長（L）': '邊坡長度（L）',
        '法面積（延長1mあたり）': '邊坡面積（每延米）',
        '法面積（延長分）': '邊坡面積（總延伸長度）',
        '角度（θ）': '角度（θ）',
        '計算に使う2つの入力欄を順にタップし、数値を入力してください。': '請依序點選兩個用於計算的輸入欄並輸入數值。',
        '計算に使う2つの入力欄を順にタップし、数値を入力してください。残りの値は自動計算されます。法勾配 1:n は、縦1に対する水平距離nを表します。':
            '請依序點選兩個用於計算的輸入欄並輸入數值。其餘數值將自動計算。邊坡坡比1:n表示垂直1對應水平距離n。',
        '法長は高さより大きい数値を入力してください': '請輸入大於高度的邊坡長度',
        '法長は水平距離より大きい数値を入力してください': '請輸入大於水平距離的邊坡長度',
        '法勾配は0より大きい数値を入力してください': '請輸入大於0的邊坡坡比',
        '水平距離は0より大きい数値を入力してください': '請輸入大於0的水平距離',
        '入力値は0以上の数値を入力してください': '請輸入大於或等於0的數值',
        '勾配比は0より大きい数値を入力してください': '請輸入大於0的坡度比',
        '角度は0度以上90度未満で入力してください': '請輸入0度以上且小於90度的角度',
        '高さは0より大きい数値を入力してください': '請輸入大於0的高度',
        '水平距離と高さに0より大きい数値を入力してください': '請輸入大於0的水平距離和高度',
        '水平距離と法長に0より大きい数値を入力してください': '請輸入大於0的水平距離和邊坡長度',
        '高さと法長に0より大きい数値を入力してください': '請輸入大於0的高度和邊坡長度',
        '距離の項目と1つ以上組み合わせて入力してください': '請選擇距離項目並至少再選一個數值',
        '勾配の入力項目を選択してください': '請選擇坡度輸入項目',
        '法長は0より大きい数値を入力してください': '請輸入大於0的邊坡長度',
        '4辺面積計算': '四邊形面積計算',
        '5辺以上面積計算': '五邊以上面積計算',
        '四角形を対角線で2つの三角形に分け、ヘロンの公式で面積を求めます。': '將四邊形沿對角線分成兩個三角形，並使用海龍公式計算面積。',
        '外周の辺': '外周邊',
        '対角線': '對角線',
        '辺A': '邊A',
        '辺B': '邊B',
        '辺C': '邊C',
        '辺D': '邊D',
        '辺を増やす': '新增邊',
        '辺を減らす': '減少邊',
        '面積を計算': '計算面積',
        '頂点Aからの対角線': '從頂點A引出的對角線',
        '頂点Aから対角線を引いて三角形に分割し、ヘロンの公式で面積を自動合算します。':
            '從頂點A引出對角線，將多邊形分成三角形，並使用海龍公式自動加總面積。',
        'すべての長さに0より大きい数値を入力してください': '請為所有長度輸入大於0的數值',
        '入力した長さでは三角形を作れません': '輸入的長度無法構成三角形',
        '外周は5辺以上入力してください': '請輸入至少5條外周邊',
        '辺数に対応する対角線を入力してください': '請輸入與邊數相對應的對角線',
        '4項目のうち3項目を入力すると、\n空欄の値を自動計算します。': '輸入4個項目中的3個，\n即可自動計算空白項目的值。',
        '例：A＝2、B＝5、C＝8 と入力すると、D＝20 を算出します。': '例：輸入A＝2、B＝5、C＝8時，將計算出D＝20。',
        '入力': '輸入',
        '自動計算': '自動計算',
        '計算する1項目を空欄にしてください': '請將要計算的一個項目留空',
        '4項目のうち3項目を入力してください': '請輸入4個項目中的3個',
        'この値では計算できません': '無法使用這些數值計算',
        '1人工生産性': '每人工生產率',
        '作業名称': '作業名稱',
        '作業情報': '作業資訊',
        '基準歩掛（任意・人工/単位）': '基準步掛（BUGAKARI）（選填、人工/單位）',
        '基準歩掛（人工/単位）': '基準步掛（BUGAKARI）（人工/單位）',
        '基準生産性（任意・単位/人日）': '基準生產率（選填、單位/人日）',
        '1人1日の施工量（単位/人日）': '每人每日施工量（單位/人日）',
        '1日の実働時間（任意）': '每日實際工時（選填）',
        '1日の標準作業時間（任意）': '每日標準工時（選填）',
        '作業人数（任意）': '作業人數（選填）',
        '作業人数': '作業人數',
        '作業日数（任意・小数可）': '作業天數（選填、可輸入小數）',
        '作業日数（小数可）': '作業天數（可輸入小數）',
        '実作業時間（任意）': '實際作業時間（選填）',
        '1日の作業時間（任意）': '每日作業時間（選填）',
        '効率差': '效率差',
        '基準歩掛': '基準步掛（BUGAKARI）',
        '実人工': '實際人工',
        '実績として保存': '儲存為實績紀錄',
        '実績を保存できませんでした': '無法儲存實績紀錄',
        '実績歩掛': '實績步掛（BUGAKARI）',
        '工種・作業名称・現場名・数量・単位・人数・日数を入力してください': '請輸入工種、作業名稱、工地名稱、數量、單位、人數和天數',
        '差': '差值',
        '延べ作業時間': '累計作業時間',
        '延べ人工時間': '總人工小時',
        'チーム1日の施工量': '團隊每日施工量',
        '実績生産性': '實績生產率',
        '時間当たり生産性': '每小時生產率',
        '基準生産性': '基準生產率',
        '生産性差': '生產率差',
        '必要人工': '所需人工',
        '必要日数': '所需天數',
        '施工数量': '施工數量',
        '施工数量と基準歩掛を入力してください': '請輸入施工數量和基準步掛（BUGAKARI）',
        '施工数量・1人1日の施工量・作業人数を入力してください': '請輸入施工數量、每人每日施工量和作業人數',
        '施工数量と1人1日の施工量を入力してください': '請輸入施工數量和每人每日施工量',
        '施工数量・作業人数・作業日数を入力してください': '請輸入施工數量、作業人數和作業天數',
        '施工日': '施工日期',
        '施工条件・備考（任意）': '施工條件・備註（選填）',
        '歩掛・生産性マスタへ保存しました': '已儲存至步掛（BUGAKARI）・生產率資料庫',
        '生産性・実績': '生產率・實績',
        '工種': '工種',
        '土工事': '土方工程',
        '地業工事': '地基工程',
        '鉄筋工事': '鋼筋工程',
        'コンクリート工事': '混凝土工程',
        '型枠工事': '模板工程',
        '舗装工事': '鋪面工程',
        '外構工事': '外部工程',
        '内装工事': '室內裝修工程',
        '保存済み実績': '已儲存的實績紀錄',
        '保存上限に達しています。既存データは引き続き閲覧できます。': '已達儲存上限，仍可查看既有資料。',
        '保存された実績はありません': '尚無已儲存的實績紀錄',
        '実績を削除': '刪除實績紀錄',
        '平均実績歩掛': '平均實績步掛（BUGAKARI）',
        '平均生産性': '平均生產率',
        '平均実績生産性': '平均實績生產率',
        '平均時間当たり生産性': '平均每小時生產率',
        '最小歩掛': '最小步掛（BUGAKARI）',
        '最大歩掛': '最大步掛（BUGAKARI）',
        'DEG（度）': 'DEG（度）',
        'RAD（ラジアン）': 'RAD（弧度）',
        '角度単位': '角度單位',
        'OFFの場合は直方体として計算': '關閉時以長方體計算',
        'この内容を単価マスタへ登録': '將此內容儲存至單價資料庫',
        'この計算履歴を削除しますか？': '要刪除這筆計算歷史嗎？',
        'そのまま追加': '直接新增',
        'コピーする明細がありません': '沒有可複製的明細',
        '一致する単価がありません': '沒有符合的單價',
        '一致する過去明細がありません': '沒有符合的過去明細',
        '今すぐ\nアップグレード': '立即\n升級',
        '仕様': '規格',
        '仮分数': '假分數',
        '作成日': '建立日期',
        '例：○○邸 外構工事': '例：○○住宅 外構工程',
        '保存上限に達しました': '已達儲存上限',
        '備考': '備註',
        '元に戻す': '復原',
        '出力する明細がありません': '沒有可輸出的明細',
        '別明細として追加': '新增為其他明細',
        '単位': '單位',
        '単位を入れ替える': '交換單位',
        '単価': '單價',
        '単価を削除': '刪除單價',
        '単価を削除しました': '已刪除單價',
        '単価を削除できませんでした': '無法刪除單價',
        '単価を更新しました': '已更新單價',
        '単価を更新できませんでした': '無法更新單價',
        '単価を検索': '搜尋單價',
        '単価を登録': '登錄單價',
        '単価を登録しました': '已登錄單價',
        '単価を登録できませんでした': '無法登錄單價',
        '単価マスタから選択': '從單價資料庫選擇',
        '単価マスタ（登録なし）': '單價資料庫（無紀錄）',
        '同じ計算内容があります': '已有相同的計算內容',
        '名称': '名稱',
        '名称を入力してください': '請輸入名稱',
        '名称未入力': '未輸入名稱',
        '名称（必須）': '名稱（必填）',
        '土工': '土方工程',
        '基本情報を保存': '儲存基本資料',
        '変換する値': '換算數值',
        '変換する種類': '換算類別',
        '変換前': '換算前',
        '変換後': '換算後',
        '変換結果': '換算結果',
        '変更': '變更',
        '変更を保存': '儲存變更',
        '契約中': '訂閱中',
        '完全版特典で有効': '已透過完整版權益啟用',
        '完全版：件数制限なし': '完整版：無數量限制',
        '宛名': '客戶名稱',
        '小数': '小數',
        '履歴を削除': '刪除歷史',
        '履歴メニュー': '歷史選單',
        '工種・名称・仕様・単位・摘要を検索': '搜尋工種、名稱、規格、單位或摘要',
        '工種小計': '工種小計',
        '帯分数': '帶分數',
        'プライバシー': '隱私權',
        '広告なし版で非表示に！': '購買無廣告版即可隱藏！',
        '広告に関する同意内容を確認・変更します': '確認或變更廣告同意選項。',
        '広告のプライバシー設定': '廣告隱私權設定',
        '広告のプライバシー設定を開けませんでした': '無法開啟廣告隱私權設定。',
        '広告スペース': '廣告區域',
        '摘要': '摘要',
        '数値を入力': '請輸入數值',
        '数量': '數量',
        '数量を加算し単価マスタへ追加しました': '已加算數量並新增至單價資料庫',
        '新しい見積': '新增估算',
        '新しい見積を作成できませんでした': '無法建立新估算',
        '既存明細へ加算': '加到現有明細',
        '既存明細へ数量を加算': '將數量加到現有明細',
        '既存明細を更新': '更新現有明細',
        '明細を追加': '新增明細',
        '最後の見積は削除できません': '無法刪除最後一份估算',
        '未入力': '未輸入',
        '未契約': '未訂閱',
        '未購入': '未購買',
        '検索をクリア': '清除搜尋',
        '検索を消去': '清除搜尋',
        '次へ': '下一步',
        '消費税（10%）': '消費稅（10%）',
        '現場': '現場',
        '現場名': '現場名稱',
        '登録された単価はありません\n右下の「単価を登録」から追加できます': '尚未登錄單價\n可從右下角的「登錄單價」新增',
        '直前の追加を取り消しました': '已復原剛才的新增',
        '税抜合計': '未稅合計',
        '税込': '含稅',
        '税込総額': '含稅總額',
        '複製': '複製',
        '見積を削除': '刪除估算',
        '見積を削除しました': '已刪除估算',
        '見積を削除できませんでした': '無法刪除估算',
        '見積を複製しました': '已複製估算',
        '見積を複製できませんでした': '無法複製估算',
        '見積を開く': '開啟估算',
        '見積を開けませんでした': '無法開啟估算',
        '見積メニュー': '估算選單',
        '見積名': '估算名稱',
        '見積基本情報': '估算基本資料',
        '見積基本情報を保存しました': '已儲存估算基本資料',
        '見積基本情報を保存できませんでした': '無法儲存估算基本資料',
        '見積明細はまだありません': '尚無估算明細',
        '見積明細をコピーできませんでした': '無法複製估算明細',
        '見積明細を保存できませんでした': '無法儲存估算明細',
        '見積明細を削除': '刪除估算明細',
        '見積明細を削除しました': '已刪除估算明細',
        '見積明細を削除できませんでした': '無法刪除估算明細',
        '見積明細を更新できませんでした': '無法更新估算明細',
        '見積明細を複製できませんでした': '無法複製估算明細',
        '見積番号': '估算編號',
        '計算根拠': '計算依據',
        '詳細未入力': '未輸入詳細資料',
        '購入済み': '已購買',
        '購入状況': '購買狀態',
        '追加して見積を開く': '新增並開啟估算',
        '追加を取り消せませんでした': '無法復原新增',
        '追加先': '新增位置',
        '追加先の見積を選択': '選擇要新增至哪份估算',
        '送信先': '傳送位置',
        '送信内容': '傳送內容',
        '送信内容の確認': '確認傳送內容',
        '過去の名称・工種・現場などを検索': '搜尋過去的名稱、工種或現場',
        '過去の見積から選択': '從過去的估算選擇',
        '過去の見積（履歴なし）': '過去的估算（無紀錄）',
        '金額未設定': '未設定金額',
        '金額（数量 × 単価）': '金額（數量 × 單價）',
        '閉じる': '關閉',
        '面積': '面積',
        '高さ': '高度',
        '高さ（V）': '高度（V）',
        'Excelファイルを作成できませんでした': '無法建立Excel檔案',
        '印刷する明細がありません': '沒有可列印的明細',
        '印刷用PDFを作成できませんでした': '無法建立列印用PDF',
        '保存': '儲存',
        '登録': '登錄',
        '登録済み': '已登錄',
        '入力を消去': '清除輸入',
        '計算する': '計算',
      }[japanese];
      if (translated != null) return translated;
    }
    if (isSimplifiedChinese) {
      final translated = const <String, String>{
        '便利計算一覧': '实用计算',
        '土量計算': '土方计算',
        '掘削・搬出': '开挖・外运',
        '埋戻し': '回填',
        '盛土': '填土',
        '比重・重量計算': '密度・重量计算',
        '勾配計算': '坡度计算',
        '面積計算': '面积计算',
        '5辺以上の面積計算': '五边以上面积计算',
        '対比計算': '比例计算',
        '歩掛・生産性計算': '步挂・生产率计算',
        'クリア': '清除',
        '見積へ': '添加到估算',
        'コピー': '复制',
        'カット': '剪切',
        'ペースト': '粘贴',
        '消去': '清除',
        '共有': '分享',
        '編集': '编辑',
        '削除': '删除',
        'スター': '星标',
        '関数一覧': '函数列表',
        '計算履歴': '计算历史',
        '履歴の並び順': '历史排序',
        '昇順': '升序',
        '降順': '降序',
        '計算式・解を検索': '搜索算式和结果',
        '検索を消去': '清除搜索',
        '検索をクリア': '清除搜索',
        '一致する履歴がありません': '没有匹配的历史记录',
        '計算履歴はまだありません': '暂无计算历史',
        '履歴メニュー': '历史菜单',
        '履歴を削除': '删除历史记录',
        'この計算履歴を削除しますか？': '要删除这条计算历史吗？',
        '小数': '小数',
        '仮分数': '假分数',
        '帯分数': '带分数',
        '見積へ送る': '发送到估算',
        '見積を開く': '打开估算',
        '送信内容': '发送内容',
        '送信先': '发送位置',
        '送信内容の確認': '确认发送内容',
        '次へ': '下一步',
        '式': '算式',
        '解': '结果',
        '式＋解': '算式＋结果',
        '角度単位': '角度单位',
        'DEG（度）': 'DEG（度）',
        'RAD（ラジアン）': 'RAD（弧度）',
        '新しい見積': '新建估算',
        '名称未設定の見積': '未命名估算',
        '見積メニュー': '估算菜单',
        '見積基本情報': '估算基本信息',
        '見積名': '估算名称',
        '見積番号': '估算编号',
        '現場': '现场',
        '現場名': '现场名称',
        '宛名': '客户名称',
        '作成日': '创建日期',
        '備考': '备注',
        '基本情報を保存': '保存基本信息',
        '見積明細はまだありません': '暂无估算明细',
        '明細を追加': '添加明细',
        '追加先': '添加位置',
        '追加先の見積を選択': '选择要添加到的估算',
        '変更': '更改',
        '変更を保存': '保存更改',
        '工種': '工种',
        '名称': '名称',
        '名称（必須）': '名称（必填）',
        '名称を入力してください': '请输入名称',
        '名称未入力': '未输入名称',
        '仕様': '规格',
        '数量': '数量',
        '単位': '单位',
        '単価': '单价',
        '金額（数量 × 単価）': '金额（数量 × 单价）',
        '摘要': '摘要',
        '計算根拠': '计算依据',
        '詳細未入力': '未输入详细信息',
        '金額未設定': '未设置金额',
        '工種小計': '工种小计',
        '税抜合計': '未税合计',
        '消費税（10%）': '消费税（10%）',
        '税込': '含税',
        '税込総額': '含税总额',
        '工種・名称・仕様・単位・摘要を検索': '搜索工种、名称、规格、单位或摘要',
        '過去の名称・工種・現場などを検索': '搜索历史名称、工种或现场',
        '単価を検索': '搜索单价',
        '単価マスタから選択': '从单价资料库选择',
        '単価マスタ（登録なし）': '单价资料库（无记录）',
        '過去の見積から選択': '从历史估算选择',
        '過去の見積（履歴なし）': '历史估算（无记录）',
        '一致する単価がありません': '没有匹配的单价',
        '一致する過去明細がありません': '没有匹配的历史明细',
        'この内容を単価マスタへ登録': '将此内容保存到单价资料库',
        '追加して見積を開く': '添加并打开估算',
        '同じ計算内容があります': '已存在相同的计算内容',
        'そのまま追加': '仍然添加',
        '既存明細を更新': '更新现有明细',
        '既存明細へ数量を加算': '数量加到现有明细',
        '既存明細へ加算': '加到现有明细',
        '別明細として追加': '作为新明细添加',
        '複製': '复制明细',
        'キャンセル': '取消',
        '未入力': '未输入',
        '未購入': '未购买',
        '購入済み': '已购买',
        '未契約': '未订阅',
        '契約中': '订阅中',
        '完全版特典で有効': '完整版权益已启用',
        '完全版：件数制限なし': '完整版：无数量限制',
        '掘削・埋戻し・搬出土・運搬回数': '开挖、回填、外运土方和运输次数',
        '材料と体積から重量を算出': '根据材料和体积计算重量',
        '高さ・水平距離・法長・角度を算出': '计算高度、水平距离、边坡长度和角度',
        '4辺と対角線から面積を算出': '根据四边和对角线计算面积',
        '外周と対角線から三角形へ分割して自動合算': '根据外周边和对角线分割为三角形并自动合计',
        '3つの値から残りの比率を算出': '根据三个数值计算剩余比例',
        '必要人工・必要日数・施工実績を計算': '计算所需人工、所需天数和施工实际记录',
        '長さ・面積・重量・勾配・土量などを変換': '换算长度、面积、重量、坡度和土方等单位',
        '体積': '体积',
        '同じ材料名が登録されています': '已登记相同的材料名称',
        '材料': '材料',
        '材料と体積から重量を計算します。初期の比重は目安のため、現場条件に合わせて変更できます。':
            '根据材料和体积计算重量。初始密度仅供参考，可按现场条件修改。',
        '材料を追加': '添加材料',
        '材料名': '材料名称',
        '材料名を入力': '请输入材料名称',
        '比重': '密度',
        '登録材料を削除': '删除已登记材料',
        '見積明細へ追加': '添加到估算明细',
        '計算結果': '计算结果',
        '追加': '添加',
        '重量を計算': '计算重量',
        'RCコンクリート': '钢筋混凝土',
        '砕石': '碎石',
        'アスファルト': '沥青',
        '砂': '砂',
        '山砂': '山砂',
        '改良土': '改良土',
        '残土': '剩余土',
        '体積に0より大きい数値を入力してください': '请输入大于0的体积',
        '比重に0より大きい数値を入力してください': '请输入大于0的密度',
        '材料データを読み込めません': '无法读取材料数据',
        '材料の比重が正しくありません': '材料密度无效',
        '入力方法': '输入方法',
        '入力項目（選択した2つから自動計算）': '输入项目（根据所选两项自动计算）',
        '勾配': '坡度',
        '勾配・法面計算': '坡度・边坡计算',
        '勾配（%）': '坡度（%）',
        '延長': '延伸长度',
        '水平距離': '水平距离',
        '水平距離（H）': '水平距离（H）',
        '法勾配': '边坡坡比',
        '法長': '边坡长度',
        '法長（L）': '边坡长度（L）',
        '法面積（延長1mあたり）': '边坡面积（每延米）',
        '法面積（延長分）': '边坡面积（总延长）',
        '角度（θ）': '角度（θ）',
        '計算に使う2つの入力欄を順にタップし、数値を入力してください。': '请依次点击两个用于计算的输入框并输入数值。',
        '高さ': '高度',
        '高さ（V）': '高度（V）',
        '法長は高さより大きい数値を入力してください': '请输入大于高度的边坡长度',
        '法長は水平距離より大きい数値を入力してください': '请输入大于水平距离的边坡长度',
        '法勾配は0より大きい数値を入力してください': '请输入大于0的边坡坡比',
        '水平距離は0より大きい数値を入力してください': '请输入大于0的水平距离',
        '入力値は0以上の数値を入力してください': '请输入大于或等于0的数值',
        '勾配比は0より大きい数値を入力してください': '请输入大于0的坡度比',
        '角度は0度以上90度未満で入力してください': '请输入0度以上且小于90度的角度',
        '高さは0より大きい数値を入力してください': '请输入大于0的高度',
        '水平距離と高さに0より大きい数値を入力してください': '请输入大于0的水平距离和高度',
        '水平距離と法長に0より大きい数値を入力してください': '请输入大于0的水平距离和边坡长度',
        '高さと法長に0より大きい数値を入力してください': '请输入大于0的高度和边坡长度',
        '4辺面積計算': '四边形面积计算',
        '5辺以上面積計算': '五边以上面积计算',
        '四角形を対角線で2つの三角形に分け、ヘロンの公式で面積を求めます。': '用对角线将四边形分成两个三角形，并使用海伦公式计算面积。',
        '外周の辺': '外周边长',
        '対角線': '对角线',
        '辺A': '边A',
        '辺B': '边B',
        '辺C': '边C',
        '辺D': '边D',
        '辺を増やす': '增加边',
        '辺を減らす': '减少边',
        '面積を計算': '计算面积',
        '頂点Aからの対角線': '从顶点A引出的对角线',
        '頂点Aから対角線を引いて三角形に分割し、ヘロンの公式で面積を自動合算します。':
            '从顶点A引出对角线，将多边形分成三角形，并用海伦公式自动合计面积。',
        'すべての長さに0より大きい数値を入力してください': '请为所有长度输入大于0的数值',
        '入力した長さでは三角形を作れません': '输入的长度无法构成三角形',
        '外周は5辺以上入力してください': '请输入至少5条外周边',
        '辺数に対応する対角線を入力してください': '请输入与边数对应的对角线',
        '4項目のうち3項目を入力すると、\n空欄の値を自動計算します。': '输入4个项目中的3个，\n即可自动计算空白值。',
        '例：A＝2、B＝5、C＝8 と入力すると、D＝20 を算出します。': '例：输入A＝2、B＝5、C＝8，将计算D＝20。',
        '入力': '输入',
        '自動計算': '自动计算',
        '1人工生産性': '每人工生产率',
        '作業名称': '作业名称',
        '作業情報': '作业信息',
        '基準歩掛（任意・人工/単位）': '基准步挂（BUGAKARI）（可选、人工/单位）',
        '基準歩掛（人工/単位）': '基准步挂（BUGAKARI）（人工/单位）',
        '基準生産性（任意・単位/人日）': '基准生产率（可选、单位/人日）',
        '1人1日の施工量（単位/人日）': '每人每日施工量（单位/人日）',
        '1日の実働時間（任意）': '每日实际工时（可选）',
        '1日の標準作業時間（任意）': '每日标准工时（可选）',
        '作業人数（任意）': '作业人数（可选）',
        '作業人数': '作业人数',
        '作業日数（任意・小数可）': '作业天数（可选、可输入小数）',
        '作業日数（小数可）': '作业天数（可输入小数）',
        '実作業時間（任意）': '实际作业时间（可选）',
        '1日の作業時間（任意）': '每日作业时间（可选）',
        '効率差': '效率差',
        '基準歩掛': '基准步挂（BUGAKARI）',
        '実人工': '实际人工',
        '実績として保存': '保存为实际记录',
        '実績を保存できませんでした': '无法保存实际记录',
        '実績歩掛': '实际步挂（BUGAKARI）',
        '工種・作業名称・現場名・数量・単位・人数・日数を入力してください': '请输入工种、作业名称、现场名称、数量、单位、人数和天数',
        '差': '差值',
        '延べ作業時間': '累计作业时间',
        '延べ人工時間': '总人工小时',
        'チーム1日の施工量': '团队每日施工量',
        '実績生産性': '实际生产率',
        '時間当たり生産性': '每小时生产率',
        '基準生産性': '基准生产率',
        '生産性差': '生产率差',
        '必要人工': '所需人工',
        '必要日数': '所需天数',
        '施工数量': '施工数量',
        '施工数量と基準歩掛を入力してください': '请输入施工数量和基准步挂（BUGAKARI）',
        '施工数量・1人1日の施工量・作業人数を入力してください': '请输入施工数量、每人每日施工量和作业人数',
        '施工数量と1人1日の施工量を入力してください': '请输入施工数量和每人每日施工量',
        '施工数量・作業人数・作業日数を入力してください': '请输入施工数量、作业人数和作业天数',
        '施工日': '施工日期',
        '施工条件・備考（任意）': '施工条件・备注（可选）',
        '歩掛・生産性マスタへ保存しました': '已保存到步挂（BUGAKARI）・生产率资料库',
        '生産性・実績': '生产率・实际记录',
        '土工事': '土方工程',
        '地業工事': '地基工程',
        '鉄筋工事': '钢筋工程',
        'コンクリート工事': '混凝土工程',
        '型枠工事': '模板工程',
        '舗装工事': '铺装工程',
        '外構工事': '室外工程',
        '内装工事': '室内装修工程',
        'ほぐし係数': '松散系数',
        '単位を入れ替える': '交换单位',
        '変換する値': '换算数值',
        '変換する種類': '换算类别',
        '変換前': '换算前',
        '変換後': '换算后',
        '数値を入力': '请输入数值',
        '締固め係数': '压实系数',
        '長さ': '长度',
        '面積': '面积',
        '重量': '重量',
        '温度': '温度',
        '圧力': '压力',
        '土量変換': '土方状态换算',
        '変換結果': '换算结果',
        '変換結果は設定画面の小数点以下桁数と丸め方法を反映します。': '换算结果会采用设置页面中的小数位数和舍入方式。',
        '尺・寸・間は、1尺＝10/33mを基準に変換します。': '尺、寸、间以1尺＝10/33米为基准进行换算。',
        '坪は、1坪＝400/121㎡（約3.30579㎡）を基準に変換します。':
            '坪以1坪＝400/121平方米（约3.30579平方米）为基准进行换算。',
        '俵は品目によって重量が異なります。この画面では参考値として米1俵＝60kgで変換します。':
            '俵的重量会因品目而异。本页面以1俵大米＝60公斤作为参考值进行换算。',
        '1:nは、垂直1に対する水平距離nとして変換します。': '1:n表示垂直高度为1时，水平距离为n。',
        '地山を基準に、ほぐし土量＝地山土量×ほぐし係数、締固め土量＝地山土量×締固め係数で変換します。係数は土質・施工条件に合わせて変更してください。':
            '以原状土为基准：松散土方＝原状土方×松散系数，压实土方＝原状土方×压实系数。请根据土质和施工条件调整系数。',
        '掘削後のほぐし土量と運搬回数を算出します。': '计算开挖后的松散土方和运输次数。',
        '構造物施工後に戻す土量を算出します。': '计算结构物施工后需要回填的土方。',
        '完成形状から必要な搬入土量を算出します。': '根据完成形状计算所需运入土方。',
        '幅': '宽度',
        '深さ': '深度',
        '掘削': '开挖',
        '掘削体積': '开挖体积',
        '地山掘削量': '原状土开挖量',
        'ほぐし土量（搬出土量）': '松散土方（外运土方）',
        '必要運搬回数': '所需运输次数',
        '運搬車両': '运输车辆',
        '積載容量': '装载容量',
        '最大積載重量': '最大载重量',
        '通常車両': '普通车辆',
        'クローラータイプ': '履带式车辆',
        'ユーザー登録車両': '用户登记车辆',
        '車両を追加': '添加车辆',
        '車両名': '车辆名称',
        '軽トラック': '轻型卡车',
        '1tトラック': '1吨卡车',
        '2tダンプ': '2吨自卸车',
        '3tダンプ': '3吨自卸车',
        '4tダンプ': '4吨自卸车',
        '8tダンプ': '8吨自卸车',
        '10tダンプ': '10吨自卸车',
        '12tダンプ': '12吨自卸车',
        'セミトレーラー（土砂）': '半挂车（土砂）',
        'クローラーダンプ 0.5t': '履带式自卸车 0.5吨',
        'クローラーダンプ 1t': '履带式自卸车 1吨',
        'クローラーダンプ 2t': '履带式自卸车 2吨',
        'クローラーダンプ 3t': '履带式自卸车 3吨',
        'm³/回': '立方米/次',
        '回': '次',
        '回（切り上げ）': '次（向上取整）',
        '端数切り上げ': '尾数向上取整',
        '控除': '扣除',
        '控除する構造物体積（任意）': '扣除的结构物体积（可选）',
        '埋戻し対象体積': '回填对象体积',
        '必要土量': '所需土方',
        '埋戻し必要土': '所需回填土',
        '余剰土': '多余土方',
        '余剰土量': '多余土方量',
        '不足土': '不足土方',
        '不足土量': '不足土方量',
        '盛土高さ': '填土高度',
        '完成盛土量': '完成填土量',
        '締固めを考慮した必要土量': '考虑压实后的所需土方',
        '必要搬入土量': '所需运入土方',
        '盛土必要土': '所需填土',
        '搬入土': '运入土方',
        '搬出土': '外运土方',
        '土砂運搬': '土方运输',
        '法面あり': '有边坡',
        '法面なし': '无边坡',
        '法勾配（垂直1：水平）': '边坡坡比（垂直1：水平）',
        '任意の水平比': '自定义水平比',
        '片側水平距離': '单侧水平距离',
        '法面形状（参考）': '边坡形状（参考）',
        '完成形状': '完成形状',
        '天端': '顶面',
        '天端の幅': '顶面宽度',
        '天端の長さ': '顶面长度',
        '底面': '底面',
        '搬入時のほぐし係数': '运入时的松散系数',
        '初期参考値 1.25': '初始参考值 1.25',
        '初期参考値 0.90': '初始参考值 0.90',
        '初期参考値 1.25（現場条件に合わせて変更可能）': '初始参考值1.25（可按现场条件修改）',
        '初期参考値 0.90（現場条件に合わせて変更可能）': '初始参考值0.90（可按现场条件修改）',
        '掘削体積 − 控除する構造物体積': '开挖体积－扣除的结构物体积',
        '地山掘削量 × ほぐし係数': '原状土开挖量×松散系数',
        '埋戻し対象体積 ÷ 締固め係数': '回填对象体积÷压实系数',
        '完成盛土量 ÷ 締固め係数': '完成填土量÷压实系数',
        '必要土量 × ほぐし係数': '所需土方×松散系数',
        '※積載容量は車両・土質・積載条件により調整してください。': '※请根据车辆、土质和装载条件调整装载容量。',
        '※候補は参考値です。設計図書や現場条件に合わせて確認・変更してください。': '※候选值仅供参考，请根据设计文件和现场条件确认并修改。',
        '※ 土量変化率・積載容量・法勾配等は、土質・車両・現場条件・設計条件等により異なります。表示値は初期値・参考値として扱い、実際の条件に合わせて変更してください。':
            '※土方变化率、装载容量和边坡坡比会因土质、车辆、现场及设计条件而异。显示值为初始参考值，请按实际条件修改。',
        '注意\n盛土高さが大きい場合は、地盤条件・法面安定・排水条件・設計図書・関係法令等を確認してください。':
            '注意\n填土较高时，请确认地基条件、边坡稳定、排水条件、设计文件及相关法规。',
        '入力しない場合は0m³': '未输入时按0立方米计算',
        '例：1 : 1.7 の場合は 1.7': '例：1 : 1.7时输入1.7',
        '任意入力': '自定义输入',
        '0より大きい数値を入力': '请输入大于0的数值',
        '0以上の数値を入力': '请输入大于或等于0的数值',
        '0より大きい数値を入力してください': '请输入大于0的数值',
        '数値を入力してください': '请输入数值',
        '有効な数値を入力してください': '请输入有效数值',
        '車両名を入力してください': '请输入车辆名称',
        '寸法・ほぐし係数・積載容量には0より大きい数値を入力してください': '请为尺寸、松散系数和装载容量输入大于0的数值',
        '寸法・締固め係数には0より大きい数値を入力してください': '请为尺寸和压实系数输入大于0的数值',
        '控除する構造物体積には0以上の数値を入力してください': '扣除的结构物体积请输入大于或等于0的数值',
        '控除する構造物体積が掘削体積を超えています': '扣除的结构物体积超过了开挖体积',
        '法長は0より大きい数値を入力してください': '边坡长度请输入大于0的数值',
        '距離の項目と1つ以上組み合わせて入力してください': '请至少输入一个距离项目并与其他项目组合',
        '保存': '保存',
        '登録': '登记',
        '登録済み': '已登记',
        '入力を消去': '清除输入',
        '計算する': '计算',
        '用語説明': '术语说明',
        'その他': '其他',
        '0で割ることはできません': '不能除以0',
        '計算できません': '无法计算',
        'この値では計算できません': '无法使用该数值计算',
        'この関数はまだ利用できません': '该函数暂不可用',
        'これ以上入力できません': '无法继续输入',
        '分数に変換できません': '无法转换为分数',
        '分数の入力を完了してから関数を選択してください': '请先完成分数输入，再选择函数',
        '先に数値を入力してください': '请先输入数值',
        '4項目のうち3項目を入力してください': '请输入4个项目中的3个',
        '計算する1項目を空欄にしてください': '请将要计算的1个项目留空',
        '勾配の入力項目を選択してください': '请选择坡度输入项目',
        '計算に使う2つの入力欄を順にタップし、数値を入力してください。残りの値は自動計算されます。法勾配 1:n は、縦1に対する水平距離nを表します。':
            '请依次点击两个用于计算的输入框并输入数值，其余数值会自动计算。边坡坡比1:n表示垂直1对应水平距离n。',
        'コピーしました': '已复制',
        'カットしました': '已剪切',
        'ペーストしました': '已粘贴',
        '元に戻す': '撤销',
        '履歴をコピーしました': '已复制历史记录',
        '履歴を削除しました': '已删除历史记录',
        '計算式を編集欄へ戻しました': '已将算式恢复到编辑框',
        '貼り付けできる計算式がありません': '没有可粘贴的算式',
        '見積へ送る計算式がありません': '没有可发送到估算的算式',
        'スターはアルティメット版で利用できます': '星标功能仅完整版可用',
        '閉じる': '关闭',
        '広告スペース': '广告区域',
        '広告なし版で非表示に！': '购买无广告版后隐藏！',
        '今すぐ\nアップグレード': '立即\n升级',
      }[japanese];
      if (translated != null) return translated;
    }
    return const <String, String>{
          'プライバシー': 'Privacy',
          '広告のプライバシー設定': 'Ad privacy choices',
          '広告に関する同意内容を確認・変更します':
              'Review or change your advertising consent choices.',
          '広告のプライバシー設定を開けませんでした': 'Could not open ad privacy choices.',
          '購入状況': 'Purchase status',
          '未購入': 'Not purchased',
          '購入済み': 'Purchased',
          '完全版特典で有効': 'Included with Full plan',
          '未契約': 'Not subscribed',
          '契約中': 'Active subscription',
          '便利計算一覧': 'Convenient calculations',
          '土量計算': 'Earthwork calculation',
          '掘削・搬出': 'Excavation & haul',
          '埋戻し': 'Backfill',
          '盛土': 'Embankment',
          '掘削・埋戻し・搬出土・運搬回数': 'Excavation, backfill, hauled soil and trips',
          '比重・重量計算': 'Density & weight',
          '材料と体積から重量を算出': 'Calculate weight from material and volume',
          '勾配計算': 'Slope calculation',
          '高さ・水平距離・法長・角度を算出': 'Calculate height, run, slope length and angle',
          '面積計算': 'Area calculation',
          '4辺と対角線から面積を算出': 'Calculate area from four sides and a diagonal',
          '5辺以上の面積計算': 'Polygon area (5+ sides)',
          '外周と対角線から三角形へ分割して自動合算':
              'Split into triangles and total automatically',
          '対比計算': 'Ratio calculation',
          '3つの値から残りの比率を算出': 'Calculate the remaining ratio from three values',
          '歩掛・生産性計算': 'Productivity calculation',
          '必要人工・必要日数・施工実績を計算':
              'Calculate labor, duration and actual productivity',
          '長さ・面積・重量・勾配・土量などを変換':
              'Convert length, area, weight, slope, earthwork and more',
          'クリア': 'Clear',
          '変換する種類': 'Conversion category',
          '変換する値': 'Value to convert',
          '数値を入力': 'Enter a number',
          '変換前': 'From',
          '変換後': 'To',
          '単位を入れ替える': 'Swap units',
          '尺・寸・間は、1尺＝10/33mを基準に変換します。':
              'SHAKU, SUN and KEN are traditional Japanese length units. This app converts them using 1 shaku = 10/33 m. Tap the information icon next to a unit for details.',
          '坪は、1坪＝400/121㎡（約3.30579㎡）を基準に変換します。':
              'TSUBO is a traditional Japanese area unit. This app uses 1 tsubo = 400/121 m² (about 3.30579 m²). Tap the information icon for details.',
          '俵は品目によって重量が異なります。この画面では参考値として米1俵＝60kgで変換します。':
              'The weight of HYO varies by commodity. This app uses 1 hyo of rice = 60 kg as a reference value. Tap the information icon for details.',
          '1:nは、垂直1に対する水平距離nとして変換します。':
              '1:n represents a horizontal distance of n for a vertical rise of 1.',
          '地山を基準に、ほぐし土量＝地山土量×ほぐし係数、締固め土量＝地山土量×締固め係数で変換します。係数は土質・施工条件に合わせて変更してください。':
              'Using JIYAMA as the reference, loose volume = natural volume × loosening factor, and compacted volume = natural volume × compaction factor. Adjust the factors for the soil and work conditions. Tap the information icon for details.',
          '変換結果は設定画面の小数点以下桁数と丸め方法を反映します。':
              'Conversion results use the decimal places and rounding method selected in Settings.',
          'ほぐし係数': 'Loosening factor',
          '締固め係数': 'Compaction factor',
          '見積へ': 'To estimate',
          '運搬車両': 'Transport vehicle',
          '通常車両': 'Standard vehicles',
          'クローラータイプ': 'Crawler vehicles',
          'ユーザー登録車両': 'User vehicles',
          '車両を追加': 'Add vehicle',
          '車両名': 'Vehicle name',
          '車両名を入力してください': 'Enter a vehicle name',
          '積載容量': 'Load capacity',
          '最大積載重量': 'Maximum payload',
          '登録': 'Save',
          '※積載容量は車両・土質・積載条件により調整してください。':
              '※ Adjust load capacity for the vehicle, soil and loading conditions.',
          '※ 土量変化率・積載容量・法勾配等は、土質・車両・現場条件・設計条件等により異なります。表示値は初期値・参考値として扱い、実際の条件に合わせて変更してください。':
              '※ Earthwork factors, load capacities and slope ratios vary with soil, vehicle, site and design conditions. Treat displayed values as defaults or references and adjust them to actual conditions.',
          '入力を消去': 'Clear input',
          '計算する': 'Calculate',
          '幅': 'Width',
          '深さ': 'Depth',
          '天端の長さ': 'Top length',
          '天端の幅': 'Top width',
          '盛土高さ': 'Embankment height',
          '法面あり': 'Include side slopes',
          'OFFの場合は直方体として計算': 'When off, calculate as a rectangular prism',
          '法勾配（垂直1：水平）': 'Slope ratio (vertical 1 : horizontal)',
          '任意入力': 'Custom',
          '任意の水平比': 'Custom horizontal ratio',
          '搬入時のほぐし係数': 'Loosening factor at delivery',
          '控除する構造物体積（任意）': 'Structure volume to deduct (optional)',
          '入力しない場合は0m³': '0 m³ when left blank',
          '地山掘削量': 'Bank excavation volume',
          'ほぐし土量（搬出土量）': 'Loose volume (hauled soil)',
          '必要運搬回数': 'Required trips',
          '掘削体積': 'Excavation volume',
          '埋戻し対象体積': 'Backfill target volume',
          '必要土量': 'Required soil volume',
          '余剰土量': 'Surplus soil',
          '不足土量': 'Soil shortage',
          '完成盛土量': 'Completed embankment volume',
          '締固めを考慮した必要土量': 'Required soil after compaction',
          '必要搬入土量': 'Required delivered soil',
          '端数切り上げ': 'Rounded up',
          '掘削後のほぐし土量と運搬回数を算出します。':
              'Calculate loose soil volume after excavation and required haul trips.',
          '構造物施工後に戻す土量を算出します。':
              'Calculate the soil volume to return after structure work.',
          '完成形状から必要な搬入土量を算出します。':
              'Calculate required delivered soil from the completed shape.',
          '変換結果': 'Result',
          '有効な数値を入力してください': 'Enter a valid number',
          '新しい見積': 'New estimate',
          '名称未設定の見積': 'Untitled estimate',
          '工種未設定': 'Uncategorized',
          '見積を削除': 'Delete estimate',
          '見積を複製しました': 'Estimate duplicated',
          '見積を複製できませんでした': 'Could not duplicate estimate',
          '最後の見積は削除できません': 'The last estimate cannot be deleted',
          '見積を削除しました': 'Estimate deleted',
          '見積を削除できませんでした': 'Could not delete estimate',
          '新しい見積を作成できませんでした': 'Could not create a new estimate',
          '見積を開けませんでした': 'Could not open estimate',
          '複製': 'Duplicate',
          '編集': 'Edit',
          'コピー': 'Copy',
          'カット': 'Cut',
          'ペースト': 'Paste',
          '消去': 'Clear',
          '共有': 'Share',
          'スター': 'Star',
          '関数一覧': 'Functions',
          '計算できません': 'Cannot calculate',
          '0で割ることはできません': 'Cannot divide by zero',
          '分数の入力を完了してから関数を選択してください':
              'Complete the fraction before selecting a function',
          'この関数はまだ利用できません': 'This function is not available yet',
          '先に数値を入力してください': 'Enter a number first',
          'これ以上入力できません': 'No more digits can be entered',
          '分数に変換できません': 'Cannot convert to a fraction',
          '0より大きい数値を入力': 'Enter a number greater than 0',
          '0以上の数値を入力': 'Enter a number of 0 or greater',
          'm³/回': 'm³/trip',
          '回': 'trips',
          '回（切り上げ）': 'trips (rounded up)',
          '完成形状': 'Completed shape',
          '土工': 'Earthwork',
          '掘削': 'Excavation',
          '搬出土': 'Hauled soil',
          '土砂運搬': 'Soil hauling',
          '埋戻し必要土': 'Required backfill soil',
          '余剰土': 'Surplus soil',
          '不足土': 'Soil shortage',
          '盛土必要土': 'Required embankment soil',
          '搬入土': 'Delivered soil',
          '地山掘削量 × ほぐし係数': 'Bank excavation volume × loosening factor',
          '掘削体積 − 控除する構造物体積': 'Excavation volume − structure volume deduction',
          '埋戻し対象体積 ÷ 締固め係数': 'Backfill target volume ÷ compaction factor',
          '完成盛土量 ÷ 締固め係数': 'Completed embankment volume ÷ compaction factor',
          '必要土量 × ほぐし係数': 'Required soil × loosening factor',
          '控除': 'Deduction',
          '法面形状（参考）': 'Side slope geometry (reference)',
          '片側水平距離': 'Horizontal run per side',
          '底面': 'Bottom dimensions',
          '法面なし': 'No side slopes',
          '天端': 'Top',
          '注意\n盛土高さが大きい場合は、地盤条件・法面安定・排水条件・設計図書・関係法令等を確認してください。':
              'Caution\nFor high embankments, check ground conditions, slope stability, drainage, design documents and applicable regulations.',
          '寸法・ほぐし係数・積載容量には0より大きい数値を入力してください':
              'Enter values greater than 0 for dimensions, loosening factor and load capacity',
          '寸法・締固め係数には0より大きい数値を入力してください':
              'Enter values greater than 0 for dimensions and compaction factor',
          '控除する構造物体積には0以上の数値を入力してください':
              'Enter a structure volume deduction of 0 or greater',
          '控除する構造物体積が掘削体積を超えています':
              'The structure volume deduction exceeds the excavation volume',
          '寸法・係数・積載容量には0より大きい数値を入力してください':
              'Enter values greater than 0 for dimensions, factors and load capacity',
          '寸法・変化率・積載容量には0より大きい数値を入力してください':
              'Enter values greater than 0 for dimensions, soil factor and load capacity',
          '構造物体積には0以上の数値を入力してください': 'Enter a structure volume of 0 or greater',
          '構造物体積が掘削量を超えています':
              'The structure volume exceeds the excavation volume',
          '材料名を入力': 'Enter a material name',
          '同じ材料名が登録されています': 'A material with this name is already saved',
          '体積に0より大きい数値を入力してください': 'Enter a volume greater than 0',
          '比重に0より大きい数値を入力してください': 'Enter a density greater than 0',
          'すべての長さに0より大きい数値を入力してください':
              'Enter a number greater than 0 for every length',
          '入力した長さでは三角形を作れません': 'The entered lengths cannot form a triangle',
          '外周は5辺以上入力してください': 'Enter at least five outer sides',
          '辺数に対応する対角線を入力してください':
              'Enter the diagonals required for the number of sides',
          '広告スペース': 'Ad space',
          '広告なし版で非表示に！': 'Remove ads with Ad-free!',
          '今すぐ\nアップグレード': 'Upgrade\nnow',
          '保存': 'Save',
          '閉じる': 'Close',
          '用語説明': 'Term information',
          '完全版：件数制限なし': 'Full plan: unlimited',
          '長さ': 'Length',
          '面積': 'Area',
          '体積': 'Volume',
          '重量': 'Weight',
          '温度': 'Temperature',
          '圧力': 'Pressure',
          '勾配': 'Slope',
          '土量変換': 'Earthwork volume',
          '追加先': 'Active',
          '見積メニュー': 'Estimate menu',
          '税込': 'Tax included',
          '4辺面積計算': 'Four-sided area',
          '5辺以上面積計算': 'Polygon area (5+ sides)',
          '面積を計算': 'Calculate area',
          '計算結果': 'Result',
          '見積明細へ追加': 'Add to estimate',
          '重量を計算': 'Calculate weight',
          '材料': 'Material',
          '材料名': 'Material name',
          '材料を追加': 'Add material',
          '登録材料を削除': 'Delete saved material',
          '比重': 'Density',
          '単位': 'Unit',
          '追加': 'Add',
          '勾配・法面計算': 'Slope calculation',
          '必要人工': 'Required labor',
          '必要日数': 'Required days',
          '生産性・実績': 'Productivity & actuals',
          '工種': 'Work category',
          '施工日': 'Work date',
          '実績として保存': 'Save as actual record',
          '保存された実績はありません': 'No saved records',
          '実績を削除': 'Delete record',
          '保存上限に達しました': 'Storage limit reached',
          '見積基本情報': 'Estimate information',
          '作成日': 'Created date',
          '基本情報を保存': 'Save information',
          '単価を登録': 'Add unit price',
          '単価を編集': 'Edit unit price',
          '単価を削除': 'Delete unit price',
          '明細を追加': 'Add detail',
          '見積明細を編集': 'Edit estimate detail',
          '変更': 'Change',
          '変更を保存': 'Save changes',
          '追加して見積を開く': 'Add and open estimate',
          '計算根拠': 'Calculation details',
          '金額（数量 × 単価）': 'Amount (quantity × unit price)',
          'この内容を単価マスタへ登録': 'Save to unit price master',
          '見積明細はまだありません': 'No estimate details yet',
          '印刷する明細がありません': 'There are no details to print',
          '印刷用PDFを作成できませんでした': 'Could not create the print PDF',
          '出力する明細がありません': 'There are no details to export',
          'Excelファイルを作成できませんでした': 'Could not create the Excel file',
          'コピーする明細がありません': 'There are no details to copy',
          '見積明細をコピーできませんでした': 'Could not copy estimate details',
          '見積明細を保存できませんでした': 'Could not save estimate details',
          '同じ計算内容があります': 'Same calculation found',
          '既存明細を更新': 'Update existing detail',
          'そのまま追加': 'Add separately',
          '既存明細へ数量を加算': 'Add quantity to existing detail',
          '既存明細へ加算': 'Add to existing detail',
          '別明細として追加': 'Add as a separate detail',
          '追加先の見積を選択': 'Choose destination estimate',
          '単価マスタから選択': 'Select from unit price master',
          '単価を検索': 'Search unit prices',
          '過去の見積から選択': 'Select from past estimates',
          '過去の名称・工種・現場などを検索': 'Search past name, category or site',
          '材料と体積から重量を計算します。初期の比重は目安のため、現場条件に合わせて変更できます。':
              'Calculate weight from material and volume. Default densities are references and can be adjusted to site conditions.',
          '登録済み': 'Saved',
          'RCコンクリート': 'Reinforced concrete',
          '砕石': 'Crushed stone',
          'アスファルト': 'Asphalt',
          '砂': 'Sand',
          '山砂': 'Pit sand',
          '改良土': 'Improved soil',
          '残土': 'Surplus soil',
          '軽トラック': 'Mini truck',
          '1tトラック': '1 t truck',
          '2tダンプ': '2 t dump truck',
          '3tダンプ': '3 t dump truck',
          '4tダンプ': '4 t dump truck',
          '8tダンプ': '8 t dump truck',
          '10tダンプ': '10 t dump truck',
          '12tダンプ': '12 t dump truck',
          'セミトレーラー（土砂）': 'Semi-trailer (soil)',
          'クローラーダンプ 0.5t': '0.5 t crawler carrier',
          'クローラーダンプ 1t': '1 t crawler carrier',
          'クローラーダンプ 2t': '2 t crawler carrier',
          'クローラーダンプ 3t': '3 t crawler carrier',
          '見積明細と単価マスタへ追加しました': 'Added to the estimate and unit price master',
          '見積明細を複製し単価マスタへ追加しました':
              'Duplicated and added to the unit price master',
          '見積明細を複製しました': 'Estimate detail duplicated',
          '見積明細を更新し単価マスタへ追加しました': 'Updated and added to the unit price master',
          '見積明細を更新しました': 'Estimate detail updated',
          '数量を加算し単価マスタへ追加しました':
              'Quantity added and saved to the unit price master',
          '既存明細を更新し単価マスタへ追加しました':
              'Existing detail updated and saved to the unit price master',
          '既存の見積明細を更新しました': 'Existing estimate detail updated',
          'コピーしました': 'Copied',
          'カットしました': 'Cut',
          'ペーストしました': 'Pasted',
          '貼り付けできる計算式がありません': 'No calculation available to paste',
          '見積へ送る計算式がありません': 'No calculation available to send',
          '履歴をコピーしました': 'History entry copied',
          '計算式を編集欄へ戻しました': 'Calculation restored for editing',
          '履歴を削除しました': 'History entry deleted',
          'スターはアルティメット版で利用できます': 'Stars are available with the full plan',
          'その他': 'Other',
          '入力方法': 'Input guide',
          '高さ（V）': 'Height (V)',
          '高さ': 'Height',
          '法長（L）': 'Slope length (L)',
          '法長': 'Slope length',
          '法勾配': 'Slope ratio',
          '角度（θ）': 'Angle (θ)',
          '勾配（%）': 'Slope (%)',
          '法面積（延長1mあたり）': 'Slope area (per 1 m length)',
          '延長': 'Length',
          '4項目のうち3項目を入力すると、\n空欄の値を自動計算します。':
              'Enter three of the four values to calculate the missing value.',
          '例：A＝2、B＝5、C＝8 と入力すると、D＝20 を算出します。':
              'Example: Enter A=2, B=5 and C=8 to calculate D=20.',
          '頂点Aから対角線を引いて三角形に分割し、ヘロンの公式で面積を自動合算します。':
              'Draw diagonals from vertex A, split the polygon into triangles, and total their areas using Heron’s formula.',
          '辺を減らす': 'Remove side',
          '辺を増やす': 'Add side',
          '外周の辺': 'Outer sides',
          '頂点Aからの対角線': 'Diagonals from vertex A',
          '見積基本情報を保存しました': 'Estimate information saved',
          '見積基本情報を保存できませんでした': 'Could not save estimate information',
          '見積明細を複製できませんでした': 'Could not duplicate the estimate detail',
          '見積明細を更新できませんでした': 'Could not update the estimate detail',
          '見積明細を削除': 'Delete estimate detail',
          '見積明細を削除しました': 'Estimate detail deleted',
          '見積明細を削除できませんでした': 'Could not delete estimate detail',
          '元に戻す': 'Undo',
          '直前の追加を取り消しました': 'The last addition was undone',
          '追加を取り消せませんでした': 'Could not undo the addition',
          '税抜合計': 'Subtotal before tax',
          '消費税（10%）': 'Tax (10%)',
          '税込総額': 'Total including tax',
          '現場': 'Site',
          '宛名': 'Client',
          '備考': 'Notes',
          '名称未入力': 'Unnamed detail',
          '金額未設定': 'Amount not set',
          '数量未設定': 'Quantity not set',
          '摘要': 'Description',
          '工種小計': 'Work subtotal',
          '名称': 'Name',
          '仕様': 'Specification',
          '数量': 'Quantity',
          '単価': 'Unit price',
          '金額': 'Amount',
          '追加して続ける': 'Add and continue',
          '単価マスタ（登録なし）': 'Unit price master (empty)',
          '過去の見積（履歴なし）': 'Past estimates (none)',
          '次回から単価マスタで検索・選択できます':
              'You can search and select it from the unit price master next time',
          '名称と単価を入力すると登録できます': 'Enter a name and unit price to save it',
          '作業情報': 'Work information',
          '施工数量と基準歩掛を入力してください':
              'Enter the work quantity and standard productivity rate',
          '施工数量・作業人数・作業日数を入力してください':
              'Enter the work quantity, workers and work days',
          '一致する単価がありません': 'No matching unit prices',
          '一致する過去明細がありません': 'No matching past details',
          'キャンセル': 'Cancel',
          '削除': 'Delete',
          '登録された単価はありません\n右下の「単価を登録」から追加できます':
              'No unit prices saved\nUse "Add unit price" at the bottom right',
          '工種・名称・仕様・単位・摘要を検索':
              'Search category, name, specification, unit or description',
          '検索をクリア': 'Clear search',
          '未入力': 'Not entered',
          '詳細未入力': 'No details',
          '単価を登録しました': 'Unit price saved',
          '単価を登録できませんでした': 'Could not save unit price',
          '単価を更新しました': 'Unit price updated',
          '単価を更新できませんでした': 'Could not update unit price',
          '単価を削除しました': 'Unit price deleted',
          '単価を削除できませんでした': 'Could not delete unit price',
          '作業名称': 'Work name',
          '現場名': 'Site name',
          '施工数量': 'Work quantity',
          '土工事': 'Earthwork',
          '地業工事': 'Groundwork',
          '鉄筋工事': 'Reinforcement work',
          'コンクリート工事': 'Concrete work',
          '型枠工事': 'Formwork',
          '舗装工事': 'Pavement work',
          '外構工事': 'Exterior work',
          '内装工事': 'Interior work',
          '基準歩掛（任意・人工/単位）': 'Standard BUGAKARI (optional, labor/unit)',
          '基準歩掛（人工/単位）': 'Standard BUGAKARI (labor/unit)',
          '基準生産性（任意・単位/人日）':
              'Baseline productivity (optional, unit/person-day)',
          '1人1日の施工量（単位/人日）': 'Daily output per person (unit/person-day)',
          '1日の実働時間（任意）': 'Actual hours per day (optional)',
          '1日の標準作業時間（任意）': 'Standard hours per day (optional)',
          '作業人数（任意）': 'Workers (optional)',
          '作業人数': 'Workers',
          '作業日数（任意・小数可）': 'Work days (optional, decimals allowed)',
          '作業日数（小数可）': 'Work days (decimals allowed)',
          '実作業時間（任意）': 'Actual work hours (optional)',
          '1日の作業時間（任意）': 'Hours per day (optional)',
          '施工条件・備考（任意）': 'Work conditions / notes (optional)',
          '延べ作業時間': 'Total work hours',
          '延べ人工時間': 'Total person-hours',
          'チーム1日の施工量': 'Team daily output',
          '実績生産性': 'Actual productivity',
          '実績歩掛': 'Actual BUGAKARI',
          '時間当たり生産性': 'Hourly productivity',
          '基準生産性': 'Baseline productivity',
          '生産性差': 'Productivity difference',
          '実人工': 'Actual labor',
          '1人工生産性': 'Productivity per worker-day',
          '基準歩掛': 'Standard BUGAKARI',
          '差': 'Difference',
          '効率差': 'Efficiency difference',
          '歩掛・生産性マスタへ保存しました': 'Saved to the BUGAKARI & productivity master',
          '実績を保存できませんでした': 'Could not save the actual record',
          '工種・作業名称・現場名・数量・単位・人数・日数を入力してください':
              'Enter category, work name, site, quantity, unit, workers and days',
          '施工数量・1人1日の施工量・作業人数を入力してください':
              'Enter the work quantity, daily output per person and workers',
          '施工数量と1人1日の施工量を入力してください':
              'Enter the work quantity and daily output per person',
          '保存済み実績': 'Saved actual records',
          '保存上限に達しています。既存データは引き続き閲覧できます。':
              'The storage limit has been reached. Existing data remains available.',
          '平均実績歩掛': 'Average actual BUGAKARI',
          '平均生産性': 'Average productivity',
          '平均実績生産性': 'Average actual productivity',
          '平均時間当たり生産性': 'Average hourly productivity',
          '最小歩掛': 'Minimum BUGAKARI',
          '最大歩掛': 'Maximum BUGAKARI',
          '名称（必須）': 'Name (required)',
          '名称を入力してください': 'Enter a name',
          '数値を入力してください': 'Enter a number',
          '単価マスタへ登録': 'Save to unit price master',
          '入力': 'Enter',
          '自動計算': 'Calculated automatically',
          '計算する1項目を空欄にしてください': 'Leave one value blank to calculate it',
          '4項目のうち3項目を入力してください': 'Enter three of the four values',
          '0より大きい数値を入力してください': 'Enter a number greater than 0',
          'この値では計算できません': 'These values cannot be calculated',
          '距離の項目と1つ以上組み合わせて入力してください': 'Select a distance and one other value',
          '勾配の入力項目を選択してください': 'Select a slope input',
          '高さは0より大きい数値を入力してください': 'Enter a height greater than 0',
          '法長は0より大きい数値を入力してください': 'Enter a slope length greater than 0',
          '水平距離は0より大きい数値を入力してください':
              'Enter a horizontal distance greater than 0',
          '法長は高さより大きい数値を入力してください':
              'Enter a slope length greater than the height',
          '法長は水平距離より大きい数値を入力してください':
              'Enter a slope length greater than the horizontal distance',
          '法勾配は0より大きい数値を入力してください': 'Enter a slope ratio greater than 0',
          '入力値は0以上の数値を入力してください': 'Enter a value of 0 or greater',
          '勾配比は0より大きい数値を入力してください': 'Enter a gradient ratio greater than 0',
          '角度は0度以上90度未満で入力してください':
              'Enter an angle from 0 degrees up to but not including 90 degrees',
          '計算に使う2つの入力欄を順にタップし、数値を入力してください。残りの値は自動計算されます。法勾配 1:n は、縦1に対する水平距離nを表します。':
              'Tap two input fields in order and enter their values. The remaining values are calculated automatically. A slope ratio of 1:n means a horizontal distance of n for a vertical rise of 1.',
          '入力項目（選択した2つから自動計算）':
              'Inputs (calculated automatically from two selected values)',
          '水平距離（H）': 'Horizontal distance (H)',
          '水平距離': 'Horizontal distance',
          '法面積（延長分）': 'Slope area (total length)',
          '見積名': 'Estimate name',
          '見積番号': 'Estimate number',
          '例：○○邸 外構工事': 'Example: Smith Residence exterior works',
          '履歴の並び順': 'History order',
          '昇順': 'Ascending',
          '降順': 'Descending',
          '計算式・解を検索': 'Search expressions and results',
          '検索を消去': 'Clear search',
          '一致する履歴がありません': 'No matching history',
          '計算履歴はまだありません': 'No calculation history yet',
          '履歴メニュー': 'History menu',
          '小数': 'Decimal',
          '仮分数': 'Improper fraction',
          '帯分数': 'Mixed fraction',
          '履歴を削除': 'Delete history',
          'この計算履歴を削除しますか？': 'Delete this calculation history?',
          '見積を開く': 'Open estimate',
          '見積へ送る': 'Send to estimate',
          '送信内容': 'Content to send',
          '送信先': 'Destination',
          '送信内容の確認': 'Confirm content',
          '次へ': 'Next',
          '式': 'Expression',
          '解': 'Result',
          '式＋解': 'Expression + result',
          'DEG（度）': 'DEG (degrees)',
          'RAD（ラジアン）': 'RAD (radians)',
          '四角形を対角線で2つの三角形に分け、ヘロンの公式で面積を求めます。':
              'Split the quadrilateral into two triangles along a diagonal and calculate the area using Heron\'s formula.',
          '辺A': 'Side A',
          '辺B': 'Side B',
          '辺C': 'Side C',
          '辺D': 'Side D',
          '対角線': 'Diagonal',
          '初期参考値 1.25（現場条件に合わせて変更可能）':
              'Initial reference value: 1.25 (adjust to site conditions)',
          '初期参考値 0.90（現場条件に合わせて変更可能）':
              'Initial reference value: 0.90 (adjust to site conditions)',
          '例：1 : 1.7 の場合は 1.7': 'Example: enter 1.7 for 1 : 1.7',
          '※候補は参考値です。設計図書や現場条件に合わせて確認・変更してください。':
              'Presets are reference values. Check and adjust them to the design documents and site conditions.',
          '初期参考値 0.90': 'Initial reference value: 0.90',
          '初期参考値 1.25': 'Initial reference value: 1.25',
        }[japanese] ??
        japanese;
  }

  String itemCount(int count) => _pick(
    japanese: '$count件',
    english: '$count items',
    simplifiedChinese: '$count项',
    traditionalChinese: '$count項',
    vietnamese: '$count mục',
    indonesian: '$count item',
    filipino: '$count item',
    myanmar: '$count ခု',
  );
  String productivityUnit(String value) {
    return switch (appLanguage) {
      AppLanguage.japanese => value,
      AppLanguage.english => switch (value) {
        '本' => 'pcs',
        '枚' => 'sheets',
        '個' => 'items',
        '箇所' => 'locations',
        '組' => 'sets',
        '式' => 'lump sum',
        _ => text(value),
      },
      AppLanguage.simplifiedChinese => switch (value) {
        '本' => '根',
        '枚' => '张',
        '個' => '个',
        '箇所' => '处',
        '組' => '组',
        '式' => '项',
        _ => text(value),
      },
      AppLanguage.traditionalChinese => switch (value) {
        '本' => '根',
        '枚' => '張',
        '個' => '個',
        '箇所' => '處',
        '組' => '組',
        '式' => '項',
        _ => text(value),
      },
      AppLanguage.vietnamese => switch (value) {
        '本' => 'cái',
        '枚' => 'tấm',
        '個' => 'cái',
        '箇所' => 'vị trí',
        '組' => 'bộ',
        '式' => 'trọn gói',
        _ => text(value),
      },
      AppLanguage.indonesian => switch (value) {
        '本' => 'buah',
        '枚' => 'lembar',
        '個' => 'buah',
        '箇所' => 'lokasi',
        '組' => 'set',
        '式' => 'lumpsum',
        _ => text(value),
      },
      AppLanguage.filipino => switch (value) {
        '本' => 'piraso',
        '枚' => 'piraso',
        '個' => 'piraso',
        '箇所' => 'lokasyon',
        '組' => 'set',
        '式' => 'lump sum',
        _ => text(value),
      },
      AppLanguage.myanmar => switch (value) {
        '本' => 'ခု',
        '枚' => 'ချပ်',
        '個' => 'ခု',
        '箇所' => 'နေရာ',
        '組' => 'စု',
        '式' => 'တစ်စုလုံး',
        _ => text(value),
      },
    };
  }

  String itemCountWithLimit(int count, int limit) => _pick(
    japanese: '$count / $limit件',
    english: '$count / $limit items',
    simplifiedChinese: '$count / $limit项',
    traditionalChinese: '$count / $limit項',
    vietnamese: '$count / $limit mục',
    indonesian: '$count / $limit item',
    filipino: '$count / $limit item',
    myanmar: '$count / $limit ခု',
  );
  String currentSaveLimit(int limit) => _pick(
    japanese: '現在の保存上限：$limit件',
    english: 'Current storage limit: $limit items',
    simplifiedChinese: '当前保存上限：$limit项',
    traditionalChinese: '目前儲存上限：$limit項',
    vietnamese: 'Giới hạn lưu hiện tại: $limit mục',
    indonesian: 'Batas penyimpanan saat ini: $limit item',
    filipino: 'Kasalukuyang limitasyon sa pag-save: $limit item',
    myanmar: 'လက်ရှိသိမ်းဆည်းနိုင်သည့်အများဆုံး: $limit ခု',
  );
  String productivityLimitMessage(int limit) => _pick(
    japanese: '現在のプランでは最大$limit件まで保存できます。完全版では100件まで保存できます。',
    english:
        'The current plan can save up to $limit records. The full plan can save up to 100 records.',
    simplifiedChinese: '当前方案最多可保存$limit条记录。完整版最多可保存100条记录。',
    traditionalChinese: '目前方案最多可儲存$limit筆紀錄。完整版最多可儲存100筆紀錄。',
    vietnamese:
        'Gói hiện tại có thể lưu tối đa $limit bản ghi. Bản đầy đủ có thể lưu tối đa 100 bản ghi.',
    indonesian:
        'Paket saat ini dapat menyimpan hingga $limit catatan. Versi lengkap dapat menyimpan hingga 100 catatan.',
    filipino:
        'Makakapag-save ng hanggang $limit tala ang kasalukuyang plano. Makakapag-save ng hanggang 100 tala ang kumpletong bersyon.',
    myanmar:
        'လက်ရှိအစီအစဉ်တွင် $limit ခုအထိ သိမ်းဆည်းနိုင်သည်။ အပြည့်အစုံဗားရှင်းတွင် 100 ခုအထိ သိမ်းဆည်းနိုင်သည်။',
  );
  String get freeEstimateLimit => _pick(
    japanese: '無料版では見積を5件まで保存できます',
    english: 'The free plan can store up to 5 estimates',
    simplifiedChinese: '免费版最多可保存5份估算',
    traditionalChinese: '免費版最多可儲存5份估算',
  );

  String specializedUnit(String id, String japanese) {
    if (isJapanese) return japanese;
    return switch (id) {
      'shaku' => '尺：SHAKU',
      'sun' => '寸：SUN',
      'ken' => '間：KEN',
      'tsubo' => '坪：TSUBO',
      'hyo' => '俵：HYO',
      'natural' => '地山：JIYAMA',
      'loose' => 'ほぐし：HOGUSHI',
      'compacted' => '締固め：SHIMEKATAME',
      _ => japanese,
    };
  }

  bool isSpecializedUnit(String id) => const {
    'shaku',
    'sun',
    'ken',
    'tsubo',
    'hyo',
    'natural',
    'loose',
    'compacted',
  }.contains(id);

  String get unitInformation => _pick(
    japanese: '単位の説明',
    english: 'Unit information',
    simplifiedChinese: '单位说明',
    traditionalChinese: '單位說明',
  );

  String get showUnitInformation => _pick(
    japanese: '単位の説明を表示',
    english: 'Show unit information',
    simplifiedChinese: '显示单位说明',
    traditionalChinese: '顯示單位說明',
  );

  String specializedUnitExplanation(String id) {
    if (isMyanmar) {
      return switch (id) {
        'shaku' =>
          'SHAKU သည် ဂျပန်ရိုးရာ အလျားယူနစ်ဖြစ်သည်။ 1 shaku = 10/33 m (0.30303 m ခန့်) ဖြစ်သည်။',
        'sun' =>
          'SUN သည် ဂျပန်ရိုးရာ အလျားယူနစ်ဖြစ်သည်။ 1 sun = 1/10 shaku = 1/33 m (0.030303 m ခန့်) ဖြစ်သည်။',
        'ken' =>
          'KEN သည် ဂျပန်ရိုးရာ အလျားယူနစ်ဖြစ်သည်။ 1 ken = 6 shaku = 20/11 m (1.81818 m ခန့်) ဖြစ်သည်။',
        'tsubo' =>
          'TSUBO သည် ဂျပန်ရိုးရာ ဧရိယာယူနစ်ဖြစ်သည်။ 1 tsubo = 400/121 m² (3.30579 m² ခန့်) ဖြစ်သည်။',
        'hyo' =>
          'HYO သည် ကုန်ပစ္စည်းအလိုက် အလေးချိန်ကွဲပြားသော ဂျပန်ရိုးရာယူနစ်ဖြစ်သည်။ ဆန် 1 hyo = 60 kg ကို ကိုးကားတန်ဖိုးအဖြစ် သုံးသည်။',
        'natural' =>
          'JIYAMA သည် မတူးဖော်မီ သဘာဝအနေအထားရှိ မြေထုထည်ဖြစ်ပြီး မြေသားလုပ်ငန်း ပြောင်းလဲတွက်ချက်မှု၏ အခြေခံဖြစ်သည်။',
        'loose' =>
          'HOGUSHI သည် တူးဖော်ပြီးနောက် ဖွလာသော မြေထုထည်ဖြစ်သည်။ ဖွမြေထုထည် = သဘာဝမြေထုထည် × ဖွကိန်း ဖြစ်သည်။',
        'compacted' =>
          'SHIMEKATAME သည် သိပ်သည်းအောင်ဖိပြီးနောက် မြေထုထည်ဖြစ်သည်။ သိပ်သည်းမြေထုထည် = သဘာဝမြေထုထည် × သိပ်သည်းကိန်း ဖြစ်သည်။',
        _ => '',
      };
    }
    if (isFilipino) {
      return switch (id) {
        'shaku' =>
          'Ang SHAKU ay tradisyonal na yunit ng haba sa Japan. Ginagamit ng app ang 1 shaku = 10/33 m (humigit-kumulang 0.30303 m).',
        'sun' =>
          'Ang SUN ay tradisyonal na yunit ng haba sa Japan. 1 sun = 1/10 shaku = 1/33 m (humigit-kumulang 0.030303 m).',
        'ken' =>
          'Ang KEN ay tradisyonal na yunit ng haba sa Japan. 1 ken = 6 shaku = 20/11 m (humigit-kumulang 1.81818 m).',
        'tsubo' =>
          'Ang TSUBO ay tradisyonal na yunit ng lawak sa Japan. 1 tsubo = 400/121 m² (humigit-kumulang 3.30579 m²).',
        'hyo' =>
          'Ang HYO ay tradisyonal na yunit ng bigat sa Japan na nag-iiba ayon sa produkto. Ginagamit ng app ang 1 hyo ng bigas = 60 kg bilang sanggunian.',
        'natural' =>
          'Ang JIYAMA ay dami ng lupa sa natural nitong kondisyon bago hukayin at ginagamit na batayang dami sa pag-convert ng gawaing lupa.',
        'loose' =>
          'Ang HOGUSHI ay dami ng maluwag na lupa pagkatapos hukayin. Dami ng maluwag na lupa = dami ng natural na lupa × expansion factor.',
        'compacted' =>
          'Ang SHIMEKATAME ay dami ng lupa pagkatapos siksikin. Dami ng siksik na lupa = dami ng natural na lupa × compaction factor.',
        _ => '',
      };
    }
    if (isIndonesian) {
      return switch (id) {
        'shaku' =>
          'SHAKU adalah satuan panjang tradisional Jepang. Aplikasi mengonversi 1 shaku = 10/33 m (sekitar 0,30303 m).',
        'sun' =>
          'SUN adalah satuan panjang tradisional Jepang. 1 sun = 1/10 shaku = 1/33 m (sekitar 0,030303 m).',
        'ken' =>
          'KEN adalah satuan panjang tradisional Jepang. 1 ken = 6 shaku = 20/11 m (sekitar 1,81818 m).',
        'tsubo' =>
          'TSUBO adalah satuan luas tradisional Jepang. 1 tsubo = 400/121 m² (sekitar 3,30579 m²).',
        'hyo' =>
          'HYO adalah satuan berat tradisional Jepang yang nilainya bergantung pada komoditas. Aplikasi menggunakan 1 hyo beras = 60 kg sebagai nilai acuan.',
        'natural' =>
          'JIYAMA adalah volume tanah dalam kondisi alami sebelum penggalian dan menjadi volume acuan untuk konversi pekerjaan tanah.',
        'loose' =>
          'HOGUSHI adalah volume tanah gembur setelah penggalian. Volume gembur = volume tanah asli × faktor pengembangan.',
        'compacted' =>
          'SHIMEKATAME adalah volume tanah setelah pemadatan. Volume padat = volume tanah asli × faktor pemadatan.',
        _ => '',
      };
    }
    if (isVietnamese) {
      return switch (id) {
        'shaku' =>
          'SHAKU là đơn vị chiều dài truyền thống của Nhật Bản. Ứng dụng quy đổi 1 shaku = 10/33 m (khoảng 0,30303 m).',
        'sun' =>
          'SUN là đơn vị chiều dài truyền thống của Nhật Bản. 1 sun = 1/10 shaku = 1/33 m (khoảng 0,030303 m).',
        'ken' =>
          'KEN là đơn vị chiều dài truyền thống của Nhật Bản. 1 ken = 6 shaku = 20/11 m (khoảng 1,81818 m).',
        'tsubo' =>
          'TSUBO là đơn vị diện tích truyền thống của Nhật Bản. 1 tsubo = 400/121 m² (khoảng 3,30579 m²).',
        'hyo' =>
          'HYO là đơn vị khối lượng truyền thống của Nhật Bản, thay đổi theo loại hàng. Ứng dụng dùng 1 hyo gạo = 60 kg làm giá trị tham khảo.',
        'natural' =>
          'JIYAMA là thể tích đất ở trạng thái tự nhiên trước khi đào, dùng làm thể tích chuẩn khi quy đổi công tác đất.',
        'loose' =>
          'HOGUSHI là thể tích đất tơi sau khi đào. Thể tích đất tơi = thể tích đất nguyên thổ × hệ số tơi.',
        'compacted' =>
          'SHIMEKATAME là thể tích đất sau khi đầm nén. Thể tích đất đầm chặt = thể tích đất nguyên thổ × hệ số đầm nén.',
        _ => '',
      };
    }
    if (isTraditionalChinese) {
      return switch (id) {
        'shaku' => '尺（SHAKU）是日本傳統長度單位。本應用程式以1尺＝10/33公尺（約0.30303公尺）換算。',
        'sun' => '寸（SUN）是日本傳統長度單位。本應用程式以1寸＝1/10尺＝1/33公尺（約0.030303公尺）換算。',
        'ken' => '間（KEN）是日本傳統長度單位。本應用程式以1間＝6尺＝20/11公尺（約1.81818公尺）換算。',
        'tsubo' => '坪（TSUBO）是日本傳統面積單位。本應用程式以1坪＝400/121平方公尺（約3.30579平方公尺）換算。',
        'hyo' => '俵（HYO）是日本傳統重量單位，重量會因物品而異。本應用程式以1俵米＝60公斤作為參考值。',
        'natural' => '地山（JIYAMA）是開挖前自然狀態的土方量，作為土方狀態換算的基準體積。',
        'loose' => 'ほぐし（HOGUSHI）是開挖後膨鬆狀態的土方量。鬆散土方量＝地山土方量×鬆散係數。',
        'compacted' => '締固め（SHIMEKATAME）是壓實後的土方量。壓實土方量＝地山土方量×壓實係數。',
        _ => '',
      };
    }
    if (isSimplifiedChinese) {
      return switch (id) {
        'shaku' => '尺（SHAKU）是日本传统长度单位。本应用按1尺＝10/33米（约0.30303米）换算。',
        'sun' => '寸（SUN）是日本传统长度单位。本应用按1寸＝1/10尺＝1/33米（约0.030303米）换算。',
        'ken' => '间（KEN）是日本传统长度单位。本应用按1间＝6尺＝20/11米（约1.81818米）换算。',
        'tsubo' => '坪（TSUBO）是日本传统面积单位。本应用按1坪＝400/121平方米（约3.30579平方米）换算。',
        'hyo' => '俵（HYO）是日本传统重量单位，重量因物品而异。本应用以1俵大米＝60千克作为参考值。',
        'natural' => '地山（JIYAMA）是开挖前自然状态的土方量，作为土方状态换算的基准体积。',
        'loose' => 'ほぐし（HOGUSHI）是开挖后膨松状态的土方量。松散土方量＝地山土方量×松方系数。',
        'compacted' => '締固め（SHIMEKATAME）是压实后的土方量。压实土方量＝地山土方量×压实系数。',
        _ => '',
      };
    }
    if (isEnglish) {
      return switch (id) {
        'shaku' =>
          '尺 (SHAKU) is a traditional Japanese unit of length. This app uses 1 shaku = 10/33 m (about 0.30303 m).',
        'sun' =>
          '寸 (SUN) is a traditional Japanese unit of length. This app uses 1 sun = 1/10 shaku = 1/33 m (about 0.030303 m).',
        'ken' =>
          '間 (KEN) is a traditional Japanese unit of length. This app uses 1 ken = 6 shaku = 20/11 m (about 1.81818 m).',
        'tsubo' =>
          '坪 (TSUBO) is a traditional Japanese unit of area. This app uses 1 tsubo = 400/121 m² (about 3.30579 m²).',
        'hyo' =>
          '俵 (HYO) is a traditional Japanese unit whose weight varies by commodity. This app uses 1 hyo of rice = 60 kg as a reference value.',
        'natural' =>
          '地山 (JIYAMA) means soil in its natural condition before excavation. It is the reference volume for earthwork conversion.',
        'loose' =>
          'ほぐし (HOGUSHI) means the expanded, loose volume after excavation. Loose volume = natural volume × loosening factor.',
        'compacted' =>
          '締固め (SHIMEKATAME) means the volume after compaction. Compacted volume = natural volume × compaction factor.',
        _ => '',
      };
    }
    return switch (id) {
      'shaku' => '尺は日本の伝統的な長さの単位です。このアプリでは1尺＝10/33m（約0.30303m）で換算します。',
      'sun' => '寸は日本の伝統的な長さの単位です。1寸＝1/10尺＝1/33m（約0.030303m）で換算します。',
      'ken' => '間は日本の伝統的な長さの単位です。1間＝6尺＝20/11m（約1.81818m）で換算します。',
      'tsubo' => '坪は日本の伝統的な面積の単位です。1坪＝400/121㎡（約3.30579㎡）で換算します。',
      'hyo' => '俵は品目によって重量が異なる日本の伝統的な単位です。このアプリでは参考値として米1俵＝60kgで換算します。',
      'natural' => '地山は、掘削前の自然な状態の土量です。土量変換の基準として使用します。',
      'loose' => 'ほぐしは、掘削後に膨らんだ土量です。ほぐし土量＝地山土量×ほぐし係数で求めます。',
      'compacted' => '締固めは、締め固め後の土量です。締固め土量＝地山土量×締固め係数で求めます。',
      _ => '',
    };
  }

  String get printA4Landscape => _pick(
    japanese: 'A4横で印刷',
    english: 'Print in A4 landscape',
    simplifiedChinese: '以A4横向打印',
    traditionalChinese: '以A4橫向列印',
  );

  String get formalPdf => _pick(
    japanese: '正式PDF',
    english: 'Formal PDF',
    simplifiedChinese: '正式PDF',
    traditionalChinese: '正式PDF',
    vietnamese: 'PDF chính thức',
    indonesian: 'PDF resmi',
    filipino: 'Opisyal na PDF',
    myanmar: 'တရားဝင် PDF',
  );

  String get pdfFileCreationFailed => _pick(
    japanese: 'PDFファイルを作成できませんでした',
    english: 'Could not create the PDF file',
    simplifiedChinese: '无法创建PDF文件',
    traditionalChinese: '無法建立PDF檔案',
    vietnamese: 'Không thể tạo tệp PDF',
    indonesian: 'Tidak dapat membuat file PDF',
    filipino: 'Hindi makagawa ng PDF file',
    myanmar: 'PDF ဖိုင်ကို ဖန်တီး၍မရပါ',
  );

  String get exportA4LandscapeExcel => _pick(
    japanese: 'A4横のExcelを出力',
    english: 'Export A4 landscape Excel',
    simplifiedChinese: '导出A4横向Excel',
    traditionalChinese: '匯出A4橫向Excel',
  );

  String get copyTableForExcel => _pick(
    japanese: 'Excel用に表をコピー',
    english: 'Copy table for Excel',
    simplifiedChinese: '复制Excel用表格',
    traditionalChinese: '複製Excel用表格',
  );

  String copiedEstimateDetails(int count) => _pick(
    japanese: '見積明細をコピーしました（$count件）',
    english: 'Copied $count estimate details',
    simplifiedChinese: '已复制估算明细（$count项）',
    traditionalChinese: '已複製估算明細（$count項）',
    vietnamese: 'Đã sao chép $count chi tiết dự toán',
    indonesian: '$count rincian estimasi telah disalin',
    filipino: 'Nakopya ang $count detalye ng estimasyon',
    myanmar: 'ခန့်မှန်းချက်အသေးစိတ် $count ခုကို ကူးယူပြီးပါပြီ',
  );

  String mergedEstimateQuantity(String quantity) => _pick(
    japanese: '既存明細の数量を$quantityへ加算しました',
    english:
        'Added the quantity to the existing detail. New quantity: $quantity',
    simplifiedChinese: '已将数量加到现有明细。新数量：$quantity',
    traditionalChinese: '已將數量加到現有明細。新數量：$quantity',
    vietnamese:
        'Đã cộng khối lượng vào chi tiết hiện có. Khối lượng mới: $quantity',
    indonesian:
        'Volume ditambahkan ke rincian yang ada. Volume baru: $quantity',
    filipino:
        'Idinagdag ang dami sa kasalukuyang detalye. Bagong dami: $quantity',
    myanmar: 'ရှိပြီးအသေးစိတ်သို့ ပမာဏထည့်ပြီးပါပြီ။ ပမာဏအသစ်: $quantity',
  );

  String deleteEstimateItemQuestion(String name) => _pick(
    japanese: '「$name」を削除しますか？',
    english: 'Delete "$name"?',
    simplifiedChinese: '要删除“$name”吗？',
    traditionalChinese: '要刪除「$name」嗎？',
    vietnamese: 'Xóa "$name"?',
    indonesian: 'Hapus "$name"?',
    filipino: 'Tanggalin ang "$name"?',
    myanmar: '"$name" ကို ဖျက်မည်လား။',
  );

  String estimateItemAddedWithCount(String message, int count) => _pick(
    japanese: '${text(message)}（$count件）',
    english: '${text(message)} ($count details)',
    simplifiedChinese: '${text(message)}（$count项）',
    traditionalChinese: '${text(message)}（$count項）',
    vietnamese: '${text(message)} ($count chi tiết)',
    indonesian: '${text(message)} ($count rincian)',
    filipino: '${text(message)} ($count detalye)',
    myanmar: '${text(message)} ($count အသေးစိတ်)',
  );

  String deleteUnitPriceQuestion(String name) => _pick(
    japanese: '「$name」を単価マスタから削除しますか？',
    english: 'Delete "$name" from the unit price master?',
    simplifiedChinese: '要从单价主数据中删除“$name”吗？',
    traditionalChinese: '要從單價資料庫刪除「$name」嗎？',
    vietnamese: 'Xóa "$name" khỏi danh mục đơn giá?',
    indonesian: 'Hapus "$name" dari daftar harga satuan?',
    filipino: 'Tanggalin ang "$name" sa listahan ng presyo kada yunit?',
    myanmar: '"$name" ကို တစ်ယူနစ်ဈေးနှုန်းစာရင်းမှ ဖျက်မည်လား။',
  );

  String selectUnitPriceMasterCount(int count) => _pick(
    japanese: '単価マスタから選択（$count件）',
    english: 'Select from unit price master ($count)',
    simplifiedChinese: '从单价主数据选择（$count项）',
    traditionalChinese: '從單價資料庫選擇（$count項）',
    vietnamese: 'Chọn từ danh mục đơn giá ($count)',
    indonesian: 'Pilih dari daftar harga satuan ($count)',
    filipino: 'Pumili sa listahan ng presyo kada yunit ($count)',
    myanmar: 'တစ်ယူနစ်ဈေးနှုန်းစာရင်းမှ ရွေးရန် ($count)',
  );

  String selectPastEstimateCount(int count) => _pick(
    japanese: '過去の見積から選択（$count件）',
    english: 'Select from past estimates ($count)',
    simplifiedChinese: '从过去的估算选择（$count项）',
    traditionalChinese: '從過去的估算選擇（$count項）',
    vietnamese: 'Chọn từ dự toán trước đây ($count)',
    indonesian: 'Pilih dari estimasi sebelumnya ($count)',
    filipino: 'Pumili sa mga nakaraang estimasyon ($count)',
    myanmar: 'ယခင်ခန့်မှန်းချက်မှ ရွေးရန် ($count)',
  );

  String get listSeparator => isJapanese ? ' ／ ' : ' / ';

  String estimateDetails(int count) => _pick(
    japanese: '$count明細',
    english: '$count details',
    simplifiedChinese: '$count项明细',
    traditionalChinese: '$count項明細',
    vietnamese: '$count chi tiết',
    indonesian: '$count rincian',
    filipino: '$count detalye',
    myanmar: '$count အသေးစိတ်',
  );

  String deleteEstimateQuestion(String name) => _pick(
    japanese: '「$name」を削除しますか？\n含まれる明細もすべて削除されます。',
    english:
        'Delete "$name"?\nAll details in this estimate will also be deleted.',
    simplifiedChinese: '要删除“$name”吗？\n该估算中的所有明细也会被删除。',
    traditionalChinese: '要刪除「$name」嗎？\n此估算中的所有明細也會被刪除。',
    vietnamese:
        'Xóa "$name"?\nTất cả chi tiết trong dự toán này cũng sẽ bị xóa.',
    indonesian:
        'Hapus "$name"?\nSemua rincian dalam estimasi ini juga akan dihapus.',
    filipino:
        'Tanggalin ang "$name"?\nTatanggalin din ang lahat ng detalye sa estimasyong ito.',
    myanmar:
        '"$name" ကို ဖျက်မည်လား။\nဤခန့်မှန်းချက်ရှိ အသေးစိတ်အားလုံးလည်း ဖျက်ပါမည်။',
  );

  String get displayAndCalculation => _pick(
    japanese: '表示・計算',
    english: 'Display & calculation',
    simplifiedChinese: '显示与计算',
    traditionalChinese: '顯示與計算',
  );
  String get theme => _pick(
    japanese: 'テーマ',
    english: 'Theme',
    simplifiedChinese: '主题',
    traditionalChinese: '主題',
  );
  String get systemTheme => _pick(
    japanese: '端末に合わせる',
    english: 'Follow device setting',
    simplifiedChinese: '跟随设备设置',
    traditionalChinese: '跟隨裝置設定',
  );
  String get whiteTheme => _pick(
    japanese: '白',
    english: 'White',
    simplifiedChinese: '白色',
    traditionalChinese: '白色',
  );
  String get grayTheme => _pick(
    japanese: 'グレー',
    english: 'Gray',
    simplifiedChinese: '灰色',
    traditionalChinese: '灰色',
  );
  String get blackTheme => _pick(
    japanese: '黒',
    english: 'Black',
    simplifiedChinese: '黑色',
    traditionalChinese: '黑色',
  );
  String get decimalPlaces => _pick(
    japanese: '小数点以下の表示桁数',
    english: 'Decimal places',
    simplifiedChinese: '小数位数',
    traditionalChinese: '小數位數',
  );
  String digits(int count) => _pick(
    japanese: '$count桁',
    english: '$count places',
    simplifiedChinese: '$count位',
    traditionalChinese: '$count位',
    vietnamese: '$count chữ số',
    indonesian: '$count digit',
    filipino: '$count digit',
    myanmar: '$count လုံး',
  );
  String get roundingMethod => _pick(
    japanese: '丸め方法',
    english: 'Rounding method',
    simplifiedChinese: '舍入方式',
    traditionalChinese: '捨入方式',
  );
  String get instantEstimateSettings => _pick(
    japanese: 'インスタント見積もり用設定',
    english: 'Instant Estimate settings',
    simplifiedChinese: '即时估算设置',
    traditionalChinese: '即時估算設定',
    vietnamese: 'Cài đặt dự toán nhanh',
    indonesian: 'Pengaturan Estimasi Instan',
    filipino: 'Mga setting ng Instant Estimate',
    myanmar: 'အမြန်ခန့်မှန်းတွက်ချက်မှု ဆက်တင်များ',
  );
  String get estimateQuantityDecimalPlaces => _pick(
    japanese: '数量の小数点桁数',
    english: 'Quantity decimal places',
    simplifiedChinese: '数量小数位数',
    traditionalChinese: '數量小數位數',
    vietnamese: 'Số chữ số thập phân của khối lượng',
    indonesian: 'Jumlah angka desimal kuantitas',
    filipino: 'Mga decimal place ng dami',
    myanmar: 'အရေအတွက်၏ ဒဿမနေရာများ',
  );
  String get estimateQuantityRoundingMethod => _pick(
    japanese: '数量の丸め方式',
    english: 'Quantity rounding method',
    simplifiedChinese: '数量舍入方式',
    traditionalChinese: '數量捨入方式',
    vietnamese: 'Phương pháp làm tròn khối lượng',
    indonesian: 'Metode pembulatan kuantitas',
    filipino: 'Paraan ng pag-round ng dami',
    myanmar: 'အရေအတွက် ပတ်လည်ပြုနည်း',
  );
  String get companyProfile => _pick(
    japanese: '自社情報',
    english: 'Company information',
    simplifiedChinese: '公司信息',
    traditionalChinese: '公司資訊',
    vietnamese: 'Thông tin doanh nghiệp',
    indonesian: 'Informasi perusahaan',
    filipino: 'Impormasyon ng kumpanya',
    myanmar: 'ကုမ္ပဏီအချက်အလက်',
  );
  String get companyProfileGuidance => _pick(
    japanese: '正式な見積書に使用する会社・事業者情報を入力してください。未入力の項目は空欄で保存できます。',
    english:
        'Enter the company or business information used on formal estimates. Blank fields can be saved.',
    simplifiedChinese: '请输入正式估价单中使用的公司或经营者信息。未填写的项目可以留空保存。',
    traditionalChinese: '請輸入正式估價單中使用的公司或業者資訊。未填寫的項目可以留空儲存。',
    vietnamese:
        'Nhập thông tin công ty hoặc đơn vị kinh doanh dùng trên báo giá chính thức. Có thể lưu các mục để trống.',
    indonesian:
        'Masukkan informasi perusahaan atau usaha untuk penawaran resmi. Kolom kosong dapat disimpan.',
    filipino:
        'Ilagay ang impormasyon ng kumpanya o negosyo para sa pormal na estima. Maaaring i-save ang mga blangkong field.',
    myanmar:
        'တရားဝင်ခန့်မှန်းစာတွင် အသုံးပြုမည့် ကုမ္ပဏီ သို့မဟုတ် လုပ်ငန်းအချက်အလက်ကို ထည့်ပါ။ အလွတ်အကွက်များကိုလည်း သိမ်းနိုင်သည်။',
  );
  String get companyNameOrTradeName => _pick(
    japanese: '会社名／屋号',
    english: 'Company / trade name',
    simplifiedChinese: '公司名称／商号',
    traditionalChinese: '公司名稱／商號',
    vietnamese: 'Tên công ty / tên thương mại',
    indonesian: 'Nama perusahaan / nama usaha',
    filipino: 'Pangalan ng kumpanya / negosyo',
    myanmar: 'ကုမ္ပဏီ / လုပ်ငန်းအမည်',
  );
  String get representativeName => _pick(
    japanese: '代表者名',
    english: 'Representative name',
    simplifiedChinese: '负责人姓名',
    traditionalChinese: '負責人姓名',
    vietnamese: 'Tên người đại diện',
    indonesian: 'Nama perwakilan',
    filipino: 'Pangalan ng kinatawan',
    myanmar: 'ကိုယ်စားလှယ်အမည်',
  );
  String get postalCode => _pick(
    japanese: '郵便番号',
    english: 'Postal code',
    simplifiedChinese: '邮政编码',
    traditionalChinese: '郵遞區號',
    vietnamese: 'Mã bưu chính',
    indonesian: 'Kode pos',
    filipino: 'Postal code',
    myanmar: 'စာပို့သင်္ကေတ',
  );
  String get addressLine1 => _pick(
    japanese: '住所1',
    english: 'Address 1',
    simplifiedChinese: '地址1',
    traditionalChinese: '地址1',
    vietnamese: 'Địa chỉ 1',
    indonesian: 'Alamat 1',
    filipino: 'Address 1',
    myanmar: 'လိပ်စာ 1',
  );
  String get addressLine2 => _pick(
    japanese: '住所2',
    english: 'Address 2',
    simplifiedChinese: '地址2',
    traditionalChinese: '地址2',
    vietnamese: 'Địa chỉ 2',
    indonesian: 'Alamat 2',
    filipino: 'Address 2',
    myanmar: 'လိပ်စာ 2',
  );
  String get phoneNumber => _pick(
    japanese: '電話番号',
    english: 'Phone number',
    simplifiedChinese: '电话号码',
    traditionalChinese: '電話號碼',
    vietnamese: 'Số điện thoại',
    indonesian: 'Nomor telepon',
    filipino: 'Numero ng telepono',
    myanmar: 'ဖုန်းနံပါတ်',
  );
  String get estimateCompanyDisplayOrder => _pick(
    japanese: '見積書での表示順',
    english: 'Display order on estimate',
    simplifiedChinese: '估价单中的显示顺序',
    traditionalChinese: '估價單上的顯示順序',
    vietnamese: 'Thứ tự hiển thị trên báo giá',
    indonesian: 'Urutan tampilan pada penawaran',
    filipino: 'Pagkakasunod ng pagpapakita sa estima',
    myanmar: 'ခန့်မှန်းစာတွင် ပြသမည့်အစဉ်',
  );
  String get companyAddressBlock => _pick(
    japanese: '住所',
    english: 'Address',
    simplifiedChinese: '地址',
    traditionalChinese: '地址',
    vietnamese: 'Địa chỉ',
    indonesian: 'Alamat',
    filipino: 'Address',
    myanmar: 'လိပ်စာ',
  );
  String get dragToReorder => _pick(
    japanese: '≡をドラッグして並べ替え',
    english: 'Drag ≡ to reorder',
    simplifiedChinese: '拖动≡调整顺序',
    traditionalChinese: '拖曳≡調整順序',
    vietnamese: 'Kéo ≡ để sắp xếp lại',
    indonesian: 'Seret ≡ untuk mengubah urutan',
    filipino: 'I-drag ang ≡ upang ayusin ang pagkakasunod',
    myanmar: 'အစဉ်ပြောင်းရန် ≡ ကို ဆွဲပါ',
  );
  String get companyProfileDisplaySettings => _pick(
    japanese: '並べ替え・Excel表示設定',
    english: 'Reorder and Excel display',
    simplifiedChinese: '排序与Excel显示设置',
    traditionalChinese: '排序與Excel顯示設定',
    vietnamese: 'Sắp xếp và hiển thị trên Excel',
    indonesian: 'Urutan dan tampilan Excel',
    filipino: 'Ayos at pagpapakita sa Excel',
    myanmar: 'အစဉ်နှင့် Excel ပြသမှု ဆက်တင်',
  );
  String get companyProfileDisplaySettingsGuidance => _pick(
    japanese: '≡で並べ替え、目のアイコンでExcelへの表示を切り替えます。',
    english: 'Drag ≡ to reorder and use the eye icon to control Excel output.',
    simplifiedChinese: '拖动≡调整顺序，使用眼睛图标切换Excel输出。',
    traditionalChinese: '拖曳≡調整順序，使用眼睛圖示切換Excel輸出。',
    vietnamese:
        'Kéo ≡ để sắp xếp và dùng biểu tượng mắt để bật/tắt xuất Excel.',
    indonesian:
        'Seret ≡ untuk mengurutkan dan gunakan ikon mata untuk keluaran Excel.',
    filipino:
        'I-drag ang ≡ para ayusin at gamitin ang eye icon para sa Excel output.',
    myanmar:
        'အစဉ်ပြောင်းရန် ≡ ကို ဆွဲပြီး Excel ထုတ်ပြမှုကို မျက်လုံးသင်္ကေတဖြင့် ပြောင်းပါ။',
  );
  String get showInExcel => _pick(
    japanese: 'Excelへ表示',
    english: 'Show in Excel',
    simplifiedChinese: '在Excel中显示',
    traditionalChinese: '在Excel中顯示',
    vietnamese: 'Hiển thị trong Excel',
    indonesian: 'Tampilkan di Excel',
    filipino: 'Ipakita sa Excel',
    myanmar: 'Excel တွင် ပြမည်',
  );
  String get hideFromExcel => _pick(
    japanese: 'Excelでは非表示',
    english: 'Hide from Excel',
    simplifiedChinese: '不在Excel中显示',
    traditionalChinese: '不在Excel中顯示',
    vietnamese: 'Ẩn trong Excel',
    indonesian: 'Sembunyikan dari Excel',
    filipino: 'Itago sa Excel',
    myanmar: 'Excel တွင် မပြပါ',
  );
  String get companyProfileExcelDisplayLimit => _pick(
    japanese: 'Excelに表示できる自社情報は5項目までです',
    english: 'Up to five company information items can be shown in Excel.',
    simplifiedChinese: 'Excel中最多可显示5项公司信息',
    traditionalChinese: 'Excel中最多可顯示5項公司資訊',
    vietnamese:
        'Có thể hiển thị tối đa 5 mục thông tin doanh nghiệp trong Excel.',
    indonesian:
        'Maksimal 5 item informasi perusahaan dapat ditampilkan di Excel.',
    filipino:
        'Hanggang 5 item ng impormasyon ng kumpanya ang maipapakita sa Excel.',
    myanmar: 'Excel တွင် ကုမ္ပဏီအချက်အလက် ၅ ခုအထိသာ ပြနိုင်သည်။',
  );
  String get notRegistered => _pick(
    japanese: '未登録',
    english: 'Not registered',
    simplifiedChinese: '未登记',
    traditionalChinese: '未登錄',
    vietnamese: 'Chưa đăng ký',
    indonesian: 'Belum terdaftar',
    filipino: 'Hindi pa nakarehistro',
    myanmar: 'မမှတ်ပုံတင်ရသေးပါ',
  );
  String get roundHalfUp => _pick(
    japanese: '四捨五入',
    english: 'Round half up',
    simplifiedChinese: '四舍五入',
    traditionalChinese: '四捨五入',
  );
  String get roundUp => _pick(
    japanese: '切上げ',
    english: 'Round up',
    simplifiedChinese: '向上取整',
    traditionalChinese: '無條件進位',
  );
  String get roundDown => _pick(
    japanese: '切捨て',
    english: 'Round down',
    simplifiedChinese: '向下取整',
    traditionalChinese: '無條件捨去',
  );
  String get angleUnit => _pick(
    japanese: '角度単位',
    english: 'Angle unit',
    simplifiedChinese: '角度单位',
    traditionalChinese: '角度單位',
  );
  String get degrees => _pick(
    japanese: '度（DEG）',
    english: 'Degrees (DEG)',
    simplifiedChinese: '度（DEG）',
    traditionalChinese: '度（DEG）',
  );
  String get radians => _pick(
    japanese: 'ラジアン（RAD）',
    english: 'Radians (RAD)',
    simplifiedChinese: '弧度（RAD）',
    traditionalChinese: '弧度（RAD）',
  );
  String get calculationHistory => _pick(
    japanese: '計算履歴',
    english: 'Calculation history',
    simplifiedChinese: '计算历史',
    traditionalChinese: '計算記錄',
  );
  String get ascendingHistory => _pick(
    japanese: '履歴を昇順で表示',
    english: 'Show history ascending',
    simplifiedChinese: '按升序显示历史',
    traditionalChinese: '依升冪顯示記錄',
  );
  String get ascendingOldest => _pick(
    japanese: '昇順（古い順）',
    english: 'Ascending (oldest first)',
    simplifiedChinese: '升序（最早优先）',
    traditionalChinese: '升冪（最舊優先）',
  );
  String get descendingNewest => _pick(
    japanese: '降順（新しい順）',
    english: 'Descending (newest first)',
    simplifiedChinese: '降序（最新优先）',
    traditionalChinese: '降冪（最新優先）',
  );
  String get confirmHistoryDeletion => _pick(
    japanese: '履歴削除時に確認する',
    english: 'Confirm before deleting history',
    simplifiedChinese: '删除历史前确认',
    traditionalChinese: '刪除記錄前確認',
  );
  String get clearAllHistory => _pick(
    japanese: '履歴をすべて削除',
    english: 'Delete all history',
    simplifiedChinese: '删除全部历史',
    traditionalChinese: '刪除全部記錄',
  );
  String get clearHistoryQuestion => _pick(
    japanese: 'スター付き以外の計算履歴をすべて削除します。よろしいですか？',
    english: 'Delete all calculation history except starred entries?',
    simplifiedChinese: '要删除除星标记录以外的全部计算历史吗？',
    traditionalChinese: '要刪除星號項目以外的全部計算記錄嗎？',
  );
  String get cancel => _pick(
    japanese: 'キャンセル',
    english: 'Cancel',
    simplifiedChinese: '取消',
    traditionalChinese: '取消',
  );
  String get delete => _pick(
    japanese: '削除',
    english: 'Delete',
    simplifiedChinese: '删除',
    traditionalChinese: '刪除',
  );
  String get historyCleared => _pick(
    japanese: '計算履歴をすべて削除しました',
    english: 'Calculation history was deleted',
    simplifiedChinese: '计算历史已全部删除',
    traditionalChinese: '已刪除全部計算記錄',
  );
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => const {
    'ja',
    'en',
    'zh',
    'vi',
    'id',
    'fil',
    'my',
  }.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    final language = locale.languageCode == 'en'
        ? AppLanguage.english
        : locale.languageCode == 'vi'
        ? AppLanguage.vietnamese
        : locale.languageCode == 'id'
        ? AppLanguage.indonesian
        : locale.languageCode == 'fil'
        ? AppLanguage.filipino
        : locale.languageCode == 'my'
        ? AppLanguage.myanmar
        : locale.languageCode == 'zh'
        ? const {'TW', 'HK', 'MO'}.contains(locale.countryCode)
              ? AppLanguage.traditionalChinese
              : AppLanguage.simplifiedChinese
        : AppLanguage.japanese;
    return SynchronousFuture(AppLocalizations(language));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
