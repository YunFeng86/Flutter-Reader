import 'language_utils.dart';

class LanguageDetector {
  LanguageDetector._();

  /// Best-effort language tag detection.
  ///
  /// Returns a canonical business language identity tag such as
  /// "zh-Hans", "zh-Hant", "en", "ja", "ko", "ru", "fr", "de", or "es",
  /// or `unknown` when uncertain.
  static String detectLanguageTag(String text) {
    final sample = _sampleText(text, maxRunes: 2000);
    if (sample.isEmpty) return unknownLanguageTag;

    var cjk = 0;
    var ja = 0;
    var ko = 0;
    var latin = 0;
    var cyrillic = 0;

    for (final code in sample.runes) {
      if (_isCjk(code)) {
        cjk++;
        continue;
      }
      if (_isHiraganaOrKatakana(code)) {
        ja++;
        continue;
      }
      if (_isHangul(code)) {
        ko++;
        continue;
      }
      if (_isCyrillic(code)) {
        cyrillic++;
        continue;
      }
      if (_isLatinLetter(code)) {
        latin++;
        continue;
      }
    }

    // Strong signals first.
    if (ja >= 24 && ja > latin) return 'ja';
    if (ko >= 24 && ko > latin) return 'ko';
    if (cyrillic >= 24 && cyrillic > latin) return 'ru';

    // CJK is ambiguous (zh/ja/ko). If CJK is dominant, assume zh.
    final totalSignal = cjk + ja + ko + latin + cyrillic;
    if (totalSignal <= 0) return unknownLanguageTag;

    if (cjk >= 20 && cjk >= latin && ja < 12 && ko < 12) {
      return _detectChineseScript(sample) ?? unknownLanguageTag;
    }

    // Fallback: Latin-heavy content.
    if (latin >= 48 && latin > cjk) {
      return _detectLatinLanguage(sample) ?? unknownLanguageTag;
    }

    return unknownLanguageTag;
  }

  static String? _detectChineseScript(String sample) {
    var simplifiedHits = 0;
    var traditionalHits = 0;
    for (final code in sample.runes) {
      if (_simplifiedOnlyRunes.contains(code)) simplifiedHits++;
      if (_traditionalOnlyRunes.contains(code)) traditionalHits++;
    }

    final totalHits = simplifiedHits + traditionalHits;
    if (totalHits < 2) return null;
    if (simplifiedHits >= traditionalHits + 2) return 'zh-Hans';
    if (traditionalHits >= simplifiedHits + 2) return 'zh-Hant';
    if (simplifiedHits >= 2 && traditionalHits == 0) return 'zh-Hans';
    if (traditionalHits >= 2 && simplifiedHits == 0) return 'zh-Hant';
    return null;
  }

  static String? _detectLatinLanguage(String sample) {
    final words = RegExp(r'[A-Za-z]{2,}')
        .allMatches(sample.toLowerCase())
        .map((m) => m.group(0)!)
        .toList(growable: false);
    if (words.length < 8) return null;

    int score(Set<String> markers) {
      var value = 0;
      for (final word in words) {
        if (markers.contains(word)) value++;
      }
      return value;
    }

    final scores = <String, int>{
      'en': score(_englishMarkers),
      'fr': score(_frenchMarkers),
      'de': score(_germanMarkers),
      'es': score(_spanishMarkers),
    };

    final ranked = scores.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = ranked.first;
    final second = ranked.length >= 2 ? ranked[1] : null;
    if (best.value < 3) return null;
    if (second != null && best.value <= second.value) return null;
    return canonicalKnownLanguageTagOrNull(best.key);
  }

  static String _sampleText(String text, {required int maxRunes}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final runes = trimmed.runes.toList(growable: false);
    if (runes.length <= maxRunes) return trimmed;
    return String.fromCharCodes(runes.take(maxRunes));
  }

  static bool _isCjk(int codePoint) {
    return (codePoint >= 0x4E00 && codePoint <= 0x9FFF) ||
        (codePoint >= 0x3400 && codePoint <= 0x4DBF);
  }

  static bool _isHiraganaOrKatakana(int codePoint) =>
      codePoint >= 0x3040 && codePoint <= 0x30FF;

  static bool _isHangul(int codePoint) =>
      codePoint >= 0xAC00 && codePoint <= 0xD7AF;

  static bool _isCyrillic(int codePoint) =>
      codePoint >= 0x0400 && codePoint <= 0x04FF;

  static bool _isLatinLetter(int codePoint) {
    if (codePoint >= 0x41 && codePoint <= 0x5A) return true;
    if (codePoint >= 0x61 && codePoint <= 0x7A) return true;
    return false;
  }

  static final Set<int> _simplifiedOnlyRunes = _buildRuneSet(
    '们这国体后为发里开东门关风气点万与业专丢严两个丰临丽举么义乌乐乔习乡书买乱争于亏云亚产亩亲亵亿仅从仑仓仪们价众优伙伞传伤伦伪伟侧侦侣侥侦侨侩侪俩俭债倾偬储儿兑党兰关兴养兽冈册军农冯冲冻净凉减凑凛几凤凭凯击凿刍划刘则刚创删别刮制刹刽剀剂剐剑剥剧劝办务劢动励劲劳势勋匀区医华协单卖卢卤卧卫却厂历厉压厌厕厘县参双发变叙叶号叹叽吁后吕吗吨听启吴呒呓呕呗员呙呛呜咏咙咛咝咤响哑哒哓哔哕哗唛唠唢唤啧啬啭啮啰啸喷喽嗫嗳嘘嘤嘱噜嚣团园围国图圆圣场坏坂块坚坛坟坠垄垅垆垒垦埘埙埚堑堕塆墙壮声壳壶壸处备复够头夹夺奁奂奋奖妆妇妈妩姗姜姹娄娅娆娇婳婴孙学宁宝实宠审宪宫宽宾寝对寻导寿将尔尘尝尧尴尸尽层屃届属屡屿岁岂岗岚岛岭岳岽岿峃峄峡峤峥峦崂崃崄崭嵘巅巩币帅师帐帘帜带帧帮帱帻帼幂幞干并广庄庆庐库应庙庞废廪开异弃张弥弯弹强归当录彟彦彻径徕御忆忏忧怀态怂怃怄怅怆总怼怿恋恒恳恶恸恹恺恻恼恽悦悫悬悭悯惊惧惨惩惫惬惭惮惯愠愤愦愿慑懑懒戏戗战戬户扑执扩扪扫扬扰抚抛抟抠抡抢护报拟拢拣拥拦拧拨择挂挚挛挜挝挞挟挠挡挣挤挥挦捞损捡换据捻掳掴掷掸掺掼揽揿搀搁搂搅携摄摅摆摇摈摊撄撑撒撵撷撸撺擞攒敌敛数斋斓斗斩断无旧时旷昙昼显晋晒晓晔晕晖暂札术朴机杀杂权杆条来杨杰松板极构枞枢枣枪枫柜柠柽栀标栈栉栋栌栎栏树栖样栾桠桥桡桢档桤桩梦梼检棁棂椁椟椠椤楼榄榇榈榉槛槟槠横樯橹橥橱橹檩欢欧欲歼殁殇残殒殓毁毂毕毙毡毵氇汇汉汤汹沟没沣沤沥沦沧沨沩沪泞泪泶洁洒洼浃浅浆浇浈浉测浍济浏浐浑浒浓涂涌涛涝涞涟涠涡涢涣涤润涧涨涩淀渊渌渍渎渐渑渔渖渗温湾湿溃溅溆滗滚滞滟滠满滢滤滥滦滨滩漤潆潇潜潴澜濑濒灏灭灯灵灾灿炀炉炜炝点炼炽烁烂烃烛烟烨热焕焖焘煴熏爱爷牍牦牵犊状犷犸犹狈狝狞独狭狮狯狰狱狲猃猎猕猡猪猫猬献獭玑玙玚玛玮环现玱玺珐珑珰珲琎琏琐琼瑶瑷璎瓒瓮电画畅畴疖疗疟疠疡疬疭疮疯疱疴痈痉痒痖痨痪痫痴瘅瘆瘗瘘瘪瘫瘾瘿癞癣皑皱盘盗盖监盐篮筹简箓箦箧箨箩箪箫篑篓篮篱簖籁籴类籼粜粝粤糁糇糍糨纟纠纡红纣纤纥约级纨纪纫纬纭纮纯纰纱纲纳纵纶纷纸纹纺纻纽纾线绀绁绂练组绅细织终绉绊绋绌绍绎经绐绑绒结绕绖绗绘给绚绛络绝绞统绠绡绢绣绤绥绦继绨绩绪绫续绮绯绰绱绲绳维绵绶绷绸绹绺绻综绽绿缀缁缂缃缄缅缆缇缈缉缊缋缌缍缎缏缐缑缓缔缕编缗缘缙缚缛缜缝缞缟缠缡缢缣缤缥缦缧缩缪缫缬缭缮缯缰缱缲缳缴缵罂网罗罚罢罴羁羟翘耢耧耸耻聂聋职聍联聩聪肃肠肤肮肴肾肿胀胁胆胜胧胪胫胶脉脍脏脐脑脓脚脱脶脸腊腭腻腼腾膑舆舰舱舻艰艳艺节芈芗芜芦苁苇苈苋苌苍苎苏苧苹范茎茏茑茔茕茧荆荐荙荚荛荜荞荟荠荡荣荤荥荦荧荨荩荪荫荬荭药莅莱莲莳获莹莺莼萚萝萤营萦萧萨葱蒇蒉蒋蒌蓝蓟蓠蓣蓥蓦蔂蔷蔹蔺蔼蕰蕲蕴薮藓蘖虏虑虚虫虽虾蚀蚁蚂蚕蚬蛊蛎蛏蛮蛰蛱蛲蛳蛴蜕蜗蝇蝈蝉蝎蝼衅衔补衬衮袄袅袜袭袯装裆裢裣裤裥褛褴见观规觅视觇览觉觊觋觌觍觎觏觐觑觞触觯訚誉誊讠计订讣认讥讦讧讨让讪讫训议讯记讱讲讳讴讵讶讷许讹论讼讽设访诀证诂诃评诅识诈诉诊诋诌词诎诏诐译诒诓诔试诖诗诘诙诚诛诜话诞诟诠诡询诣诤该详诧诨诩诪诫诬语诮误诰诱诲诳说诵诶请诸诹诺读诼诽课诿谀谁谂调谄谅谆谇谈谊谋谌谍谎谏谐谑谒谓谔谕谖谗谘谙谚谛谜谝谞谟谠谡谢谣谤谥谦谧谨谩谪谫谬谭谮谯谱谲谳谴谵谶贝贞负贡财责贤败账货质贩贪贫贬购贮贯贰贱贲贳贴贵贶贷贸费贺贻贼贽贾贿赀赁赂赃资赅赆赇赈赉赊赋赌赍赎赏赐赑赒赓赔赕赖赘赙赚赛赜赝赞赟赠赡赢赣赵赶趋趱跄跞践跶跷跸跹跻踊踌踪踬踯蹑蹒蹰蹿躏躜躯车轧轨轩轪轫转轭轮软轰轱轲轳轴轵轶轷轸轹轺轻轼载轾轿辀辁辂较辄辅辆辇辈辉辊辋辌辍辎辏辐辑辒输辔辕辖辗辘辙辚辞辩辫边辽达迁过迈运还这进远违连迟迩迳迹适选逊递逦逻遗遥邓邮邻郏郐郑郓郦郧郸酂酝酱酽酾酿释里鉴銮錾钅钆钇针钉钊钋钌钍钎钏钐钒钓钔钕钗钙钚钛钜钝钞钟钠钡钢钣钥钦钧钨钩钪钫钬钭钮钯钰钱钲钳钴钵钶钷钸钹钺钻钼钽钾钿铀铁铂铃铄铅铆铈铉铊铋铌铍铎铐铑铒铕铗铘铙铛铜铝铞铟铠铡铢铣铤铥铦铧铨铩铪铫铬铭铮铯铰铱铲铳铴铵银铷铸铹铺铻铼铽链铿销锁锂锄锅锆锇锈锉锊锋锌锍锎锏锐锑锒锓锔锕锖锗错锚锛锜锝锞锟锡锢锣锤锥锦锧锨锩锪锫锬锭键锯锰锱锲锳锴锵锶锷锸锹锺锻锼锽锾镀镁镂镃镄镅镆镇镈镉镊镋镌镍镎镏镐镑镒镓镔镕镖镗镘镙镚镛镜镝镞镟镠镡镢镣镤镥镦镧镨镩镪镫镬镭镮镯镰镱镲镳镴镶长门闩闪闭问闯闰闱闲间闵闶闷闸闹闺闻闼闽闾阀阁阂阃阄阅阆阈阉阊阋阌阍阎阏阐阑阒阓阔阕阖阗阘阙阚队阳阴阵阶际陆陇陈陉陕陧陨险随隐隶隽难雏雠雳雾霁霉靓静面鞑鞒鞯韦韧韩韪韫韬韵页顶顷项顺须顼顽顾顿颀颁颂预颅领颇颈颉颊颋颌颍颏颐频颓颔颖颗题颙颚颛颜额颞颟颠颡颢颤颥颦风飏飐飑飒飓飔飕飖飗飞饣饤饥饦饧饨饩饪饫饬饭饮饯饰饱饲饳饴饵饶饷饸饹饺饻饼饽饿馀馁馂馃馄馅馆馇馈馉馊馋馌馍馎馏馐馑馒馓馔馕马驭驮驯驰驱驲驳驴驵驶驷驸驹驺驻驼驽驾驿骀骁骂骃骄骅骆骇骈骉骊骋验骍骎骏骐骑骒骓骗骚骘骙骚骛骜骝骞骟骠骡骤骥骦髅髋髌鬓魇魉鱼鱽鱾鱿鲀鲁鲂鲃鲄鲅鲆鲇鲈鲉鲊鲋鲌鲍鲎鲏鲐鲑鲒鲓鲔鲕鲖鲗鲘鲙鲚鲛鲜鲝鲞鲟鲠鲡鲢鲣鲤鲥鲦鲧鲨鲩鲪鲫鲬鲭鲮鲯鲰鲱鲲鲳鲴鲵鲶鲷鲸鲹鲺鲻鲼鲽鲾鲿鳀鳁鳂鳃鳄鳅鳆鳇鳈鳉鳊鳋鳌鳍鳎鳏鳐鳑鳒鳓鳔鳕鳖鳗鳘鳙鳚鳛鳜鳝鳞鳟鳠鳡鳢鳣鸟鸡鸣鸥鸦鸧鸨鸩鸪鸭鸯鸰鸱鸲鸳鸴鸵鸶鸷鸸鸹鸺鸻鸼鸽鸾鸿鹀鹁鹂鹃鹄鹅鹆鹇鹈鹉鹊鹋鹌鹍鹏鹐鹑鹒鹓鹔鹕鹖鹗鹘鹙鹚鹛鹜鹝鹞鹟鹠鹡鹢鹣鹤鹥鹦鹧鹨鹩鹪鹫鹬鹭鹰鹱鹲鹳鹴鹾麦麸黄黉黡黩黪黾鼋鼍鼹齄齐齑齿龀龃龄龅龆龇龈龉龊龋龌龙龚龛龟',
  );
  static final Set<int> _traditionalOnlyRunes = _buildRuneSet(
    '們這國體後為發裡開東門關風氣點萬與業專嚴兩個豐臨麗舉麼義烏樂喬習鄉書買亂爭於虧雲亞產畝親褻億僅從侖倉儀價眾優夥傘傳傷倫偽偉側偵侶僥僑儈儕倆儉債傾傯儲兒兌黨蘭關興養獸岡冊軍農馮沖凍淨涼減湊凜幾鳳憑凱擊鑿芻劃劉則剛創刪別颳製剎劊剴劑剮劍剝劇勸辦務勱動勵勁勞勢勳勻區醫華協單賣盧鹵臥衛卻廠歷厲壓厭廁釐縣參雙發變敘葉號嘆嘰籲後呂嗎噸聽啟吳噓囈嘔唄員咼嗆嗚詠嚨嚀噝詫響啞噠嘵嗶噦譁嘜嘮嗩喚嘖嗇囀齧囉嘯噴嘍囁噯嚶囑嚕囂團園圍國圖圓聖場壞阪塊堅壇墳墜壟壠壚壘墾塒壎堝塹墮灣牆壯聲殼壺壼處備複夠頭夾奪奩奐奮獎妝婦媽嫵姍薑奼婁婭嬈嬌嫿嬰孫學寧寶實寵審憲宮寬賓寢對尋導壽將爾塵嘗堯尷屍盡層屭屆屬屢嶼歲豈崗嵐島嶺嶽崬巋嶠崢巒嶗嶸巔鞏幣帥師帳簾幟帶幀幫幬幘幗冪襆乾並廣莊慶廬庫應廟龐廢廩異棄張彌彎彈強歸當錄彥徹徑徠禦憶懺憂懷態慫愴悵愷惻惱惲悅慪懸慳憫驚懼慘懲憊愜慚憚慣慍憤憒願懾懣懶戲戧戰戩戶撲執擴捫掃揚擾撫拋摶摳掄搶護報擬攏揀擁攔擰撥擇掛摯攣掗撾撻挾撓擋掙擠揮撏撈損撿換據撚擄摑擲撣摻摜攬撳攙擱摟攪攜攝攄擺搖擯攤攖撐灑攆擷擼攛擻攢敵斂數齋斕鬥斬斷無舊時曠曇晝顯晉曬曉曄暈暉暫劄術樸機殺雜權桿條來楊傑鬆闆極構樅樞棗槍楓櫃檸檉梔標棧櫛棟櫨櫟欄樹棲樣欒椏橋橈楨檔榿樁夢檮檢梲櫺槨櫝槧欏樓欖櫬櫚櫸檻檳櫧橫檣櫓櫫櫥檁歡歐慾殲歿殤殘殞殮毀轂畢斃氈毿氌匯漢湯洶溝沒灃漚瀝淪滄渢溈滬濘淚澩潔灑窪浹淺漿澆湞溮測澮濟瀏滻渾滸濃塗湧濤澇淶漣潿渦溳渙滌潤澗漲澀澱淵淥漬瀆漸澠漁瀋滲溫灣溼潰濺漵潷滾滯灩灄滿瀅濾濫灤濱灘濫瀠瀟潛瀦瀾瀨瀕灝滅燈靈災燦煬爐煒熗點煉熾爍爛烴燭煙燁熱煥燜燾熅燻愛爺牘犛牽犢狀獷獁猶狽獮獰獨狹獅獪猙獄猻獫獵獼玀豬貓蝟獻獺璣璵瑒瑪瑋環現瑲璽琺瓏璫琿璡璉瑣瓊瑤璦瓔瓚甕電畫暢疇癤療瘧癘瘍癧瘲瘡瘋皰屙癰痙癢瘂癆瘓癇癡癉瘮瘞瘺癟癱癮癭癩癬皚皺盤盜蓋監鹽籃籌簡籙簀篋籜籮簞簫簣簍籃籬籪籟糴類秈糶糲粵糝餱餈糨糹糾紆紅紂纖紇約級紈紀紉緯紜紘純紕紗綱納縱綸紛紙紋紡紵紐紓線紺紲紱練組紳細織終縐絆紼絀紹繹經紿綁絨結繞紲絎繪給絢絳絡絕絞統綆綃絹繡綌綏絛繼綈績緒綾續綺緋綽緔緄繩維綿綬繃綢綯綹綣綜綻綠綴緇緙緗緘緬纜緹緲緝縕繢緦綞緞緶線緱緩締縷編緡緣縉縛縟縝縫縗縞纏縭縊縑繽縹縵縲縮繆繅纈繚繕繒韁繾繰繯繳纘罌網羅罰罷羈羥翹耬聳恥聶聾職聹聯聵聰肅腸膚骯餚腎腫脹脅膽勝朧臚脛膠脈膾髒臍腦膿腳脫腡臉臘齶膩靦騰臏輿艦艙艫艱豔藝節羋薌蕪蘆蓯葦藶莧萇蒼苧蘇蘋範莖蘢蔦塋煢繭荊薦薘莢蕘蓽蕎薈薺蕩榮葷滎犖熒蕁藎蓀蔭蕒葒藥蒞萊蓮蒔獲瑩鶯蒓籮螢營縈蕭薩蔥蕆蕢蔣蔞藍薊蘺蕷鎣驀薔蘞藺藹蘊蘄蘞擄慮虛蟲雖蝦蝕蟻螞蠶蜆蠱蠣蟶蠻蟄莢蟯螄蠐蛻蝸蠅蟈蟬蠍螻釁銜補襯袞襖裊襪襲襏裝襠褳襝褲襇褸襤見觀規覓視覘覽覺覬覡覿覥覦覯覲覷觴觸觶譽謄訁計訂訃認譏訐訌討讓訕訖訓議訊記訒講諱謳詎訝訥許訛論訟諷設訪訣證詁訶評詛識詐訴診詆謅詞詘詔詖譯詒誆誄試詿詩詰詼誠誅詵話誕詬詮詭詢誼諍該詳詫諢詡譸誡誣語誚誤誥誘誨誑說誦誒請諸諏諾讀諑誹課諉諂調諄談誼謀諶諜謊諫諧謔謁謂諤諭諼讒諮諳諺諦謎諞諝謨讜謖謝謠謗諡謙謐謹謾謫譾謬譚譖譙譜譎讞譴譫讖貝貞負貢財責賢敗賬貨質販貪貧貶購貯貫貳賤賁貰貼貴貺貸貿費賀貽賊贄賈賄貲賃賂贓資賅贐賕賑賚賒賦賭齎贖賞賜贔賙賡賠賧賴贅賻賺賽賾贗贊贇贈贍贏贛趙趕趨躥踉躒踐躂蹺蹕躚躋踴躊蹤躓躑躡蹣躕躥轎軀車軋軌軒軑軔轉軛輪軟轟軲軻轤軸軹軼軤軫轢軺輕軾載輊轎輀輁輂較輒輔輛輦輩輝輥輞輬輟輜輳輻輯轀輸轡轅轄輾轆轍轔辭辯辮邊遼達遷過邁運還這進遠違連遲邇逕跡適選遜遞邐邏遺遙鄧郵鄰郟鄶鄭鄆酈鄖鄲醞醬釅釃釀釋裡鑑鑾鏨釒釓釔針釘釗釙釕釷釺釧釤釩釣鍆釹釵鈣鈈鈦鉅鈍鈔鐘鈉鋇鋼鈑鑰欽鈞鎢鉤鈧鈁鈥鈄鈕鈀鈺錢鉦鉗鈷缽鈳鉕鈽鈸鉞鑽鉬鉭鉀鈿鈾鐵鉑鈴鑠鉛鉚鈰鉉鉈鉍鈮鈹鐸銬銠鉺銪鋏鋣鐃鐺銅鋁銩銦鎧鍘銖銑鋌銩銛鏵銓鎩鉿銚鉻銘錚銫鉸銥鏟銃鐋銨銀銣鑄鐒鋪鋙錸鋱鏈鏗銷鎖鋰鋤鍋鋯鍔鏽銼鋝鋒鋅鎦鐦鐧銳銻鋃鋟鋦錒錆鍺錯錨錛錡鍀錁錕錫錮鑼錘錐錦質鍁錈鍃錇錟錠鍵鋸錳錙鍥鍈鍇鏘鍶鍔鍤鍬鍾鍛鎪鍠鍰鍍鎂鏤鏹鑞鎮鎛鎘鑷钂鐫鎳鎿鎦鎬鎊鎰鎵鑌鏞鏢鏜鏝鏍鏰鏞鏡鏑鏃鏇鏐鐔鐝鐐鏷鑥鐓鑭鐠鑹鏹鐙鑊鐳鐶鐲鐮鐿鑔鑣鑞鑲長門閂閃閉問闖閏闈閒間閔閌悶閘鬧閨聞闥閩閭閥閣閡閫閬閾閹閶鬩閿閽閻閼闡闌闃闠闊闋闔闐闒闕闞隊陽陰陣階際陸隴陳陘陝隉隕險隨隱隸雋難雛讎靂霧霽黴靚靜麵韃鞽韉韋韌韓韙韞韜韻頁頂頃項順須頊頑顧頓頎頒頌預顱領頗頸頡頰頲頜潁頦頤頻頹頷穎顆題顒顎顓顏額顳顢顛顙顥顫顬顰風颺颭颮颯颶颸颼颻飀飛飠飣飢飥餳飩餼飪飫飭飯飲餞飾飽飼飿飴餌饒餉餄餎餃餏餅餑餓餘餒餕餜餛餡館餷饋餶餿饞饁饃餺餾饈饉饅饊饌饢馬馭馱馴馳驅馹駁驢駔駛駟駙駒騶駐駝駑駕驛駘驍罵駰驕驊駱駭駢驫驪騁驗騂騏騎騍騅騙騷驁驫驃驄驟驥驦髏髖髕鬢魘魎魚魛魢魷魨魯魴魺魷魯鮒鮑鮍鮎鮐鮭鮚鮜鮞鮪鮳鮐鮺鮫鮮鮝鯀鯊鯇鯒鯖鯪鯫鯱鯰鯷鯽鯿鰱鰹鯉鯴鰷鯒鯛鯨鯴鯔鰈鰍鰒鰉鰁鰓鰐鰭鰨鰥鰩鰱鰲鰳鰾鱈鱉鰻鰵鱅鰼鱖鱔鱗鱒鱠鱧鱣鳥雞鳴鷗鴉鶬鴇鴆鴣鴨鴦鴒鴟鴝鴛鷽鴕鷥鷙鴯鴰鵂鴴鴿鸞鴻鵐鵓鸝鵑鵠鵝鵒鷳鵜鵡鵲鶓鵪鵬鶉鶊鵷鶘鶚鶻鶖鶿鶼鷀鷸鷺鷹鸛鸞鸚鸝鸞鹺麥麩黃黌黶黷黲黽黿鼉鼴齊齏齒齔齙齜齟齡齠齦齬齪齲齷龍龔龕龜',
  );
  static const Set<String> _englishMarkers = <String>{
    'the',
    'and',
    'this',
    'that',
    'with',
    'from',
    'into',
    'for',
    'have',
    'has',
    'was',
    'were',
    'are',
    'is',
    'of',
    'to',
    'in',
  };
  static const Set<String> _frenchMarkers = <String>{
    'le',
    'la',
    'les',
    'des',
    'une',
    'est',
    'pour',
    'dans',
    'avec',
    'que',
    'qui',
    'pas',
    'du',
    'au',
    'et',
  };
  static const Set<String> _germanMarkers = <String>{
    'der',
    'die',
    'das',
    'und',
    'ist',
    'nicht',
    'mit',
    'den',
    'auf',
    'von',
    'ein',
    'eine',
    'im',
    'zu',
  };
  static const Set<String> _spanishMarkers = <String>{
    'el',
    'la',
    'los',
    'las',
    'una',
    'uno',
    'de',
    'que',
    'en',
    'con',
    'para',
    'por',
    'es',
    'del',
    'y',
  };

  static Set<int> _buildRuneSet(String chars) => chars.runes.toSet();
}
