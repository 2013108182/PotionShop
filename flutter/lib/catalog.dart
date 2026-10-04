/// Production ingredients. Tutorial samples deliberately live outside this list.
class Ingredient {
  final String id, name, lore;
  final int price;
  final bool rare, expansion;
  const Ingredient(this.id, this.name, this.lore, this.price,
      {this.rare = false, this.expansion = false});
}

const ingredients = [
  Ingredient('web', '밤의 거미줄', '고요하게 감싸고 움직임을 느리게 해요.', 2),
  Ingredient('tear', '정령의 눈물', '마음의 불안을 가라앉히는 물방울이에요.', 2),
  Ingredient('moon', '달빛 결정', '달빛을 머금은 돌. 감각을 예민하게 만들어요.', 2),
  Ingredient('salt', '심해 소금', '깊은 바다에서 얻은 소금. 흐릿한 감각을 맑게 해요.', 2),
  Ingredient('mushroom', '별빛 버섯', '어두운 숲에서 은은하게 빛나는 버섯이에요.', 2),
  Ingredient('petal', '황혼 꽃잎', '따뜻한 체온과 붉은 기운을 되찾아줘요.', 2),
  Ingredient('root', '맨드레이크', '잠든 씨앗의 생명력을 깨워요.', 5, rare: true),
  Ingredient('fairy', '요정 가루', '우연을 살짝 비틀어 작은 행운을 가져와요.', 5, rare: true),
  Ingredient('feather', '솜구름 깃털', '떨어지는 속도를 줄여 작은 물건이 천천히 내려와요.', 3, expansion: true),
  Ingredient('resin', '은나무 수지', '표면에 얇고 유연한 막을 만들어 물기를 막고 붙잡아요.', 3, expansion: true),
  Ingredient('reed', '메아리 갈대', '작은 소리를 받아 부드럽게 울려 보내요.', 3, expansion: true),
  Ingredient('aromaleaf', '숨결 잎', '은은한 향을 천천히 흘려보내요.', 3, expansion: true),
];

String ingredientName(String id) => ingredients.firstWhere((i) => i.id == id).name;

class Potion {
  final String id, name, description;
  final List<String> recipe;
  final int price;
  final String useLimit;
  final String? unlockResidentId;
  final int recipeVersion;
  const Potion(this.id, this.name, this.description, this.recipe, this.price,
      {this.useLimit = '', this.unlockResidentId, this.recipeVersion = 1});
  int get slotCount => recipe.length;
  String get ingredientText => recipe.map(ingredientName).join(' → ');
  int get materialCost => recipe.fold(0,
      (sum, id) => sum + ingredients.firstWhere((i) => i.id == id).price);
}

const potions = [
  Potion('sleep', '깊은 밤의 숙면 물약', '달빛처럼 고요한 잠을 선물해요.', ['web', 'tear', 'moon'], 35,
      useLimit: '휴식을 돕는 약이에요. 밤샘이나 졸음을 쫓는 용도는 아니에요.'),
  Potion('sight', '올빼미의 시야 물약', '어두운 숲에서도 길을 잃지 않아요.', ['moon', 'salt', 'mushroom'], 38,
      useLimit: '어두운 표지를 읽도록 도와요. 벽 너머를 보거나 시력을 치료하지 않아요.', unlockResidentId: 'ellie'),
  Potion('warmth', '오래가는 온기 물약', '천 주머니에 부드러운 온기를 오래 남겨요.', ['petal', 'tear', 'web'], 36,
      useLimit: '반죽상자나 손잡이 천에 써요. 마시거나 불을 피우는 약이 아니에요.', unlockResidentId: 'mina'),
  Potion('sprout', '봄깨움 물약', '잠든 살아 있는 씨앗이 싹을 틔우도록 도와요.', ['root', 'tear', 'petal'], 45,
      useLimit: '죽은 식물을 되살리거나 수확을 즉시 끝내지는 않아요.', unlockResidentId: 'robin'),
  Potion('luck', '작은 행운 물약', '미처 보지 못한 작은 기회를 눈여겨보게 해요.', ['fairy', 'moon', 'tear'], 45,
      useLimit: '원하는 결과나 당첨을 보장하지 않아요.', unlockResidentId: 'sage'),
  Potion('hush', '고요한 서가 물약', '작은 덜컥 소리의 잔향을 부드럽게 줄여요.', ['web', 'reed', 'tear'], 40,
      useLimit: '사람의 말이나 경보를 지우지 않아요.', unlockResidentId: 'nari'),
  Potion('softfall', '깃털받침 물약', '포장한 작은 물건이 떨어질 때 충격을 덜어줘요.', ['feather', 'web', 'tear'], 43,
      useLimit: '사람을 날게 하거나 높은 곳의 안전장비를 대신하지 않아요.', unlockResidentId: 'jun'),
  Potion('raincoat', '빗방울 외투 물약', '종이와 천에 유연한 방수막을 입혀요.', ['resin', 'web', 'petal'], 41,
      useLimit: '물속 호흡이나 영구 방수 효과는 없어요.', unlockResidentId: 'luna'),
  Potion('echo', '맑은 메아리 물약', '작은 기계 진동을 구별하도록 귀를 도와요.', ['reed', 'moon', 'salt'], 43,
      useLimit: '벽 너머 대화를 엿듣는 약이 아니에요.', unlockResidentId: 'doran'),
  Potion('calm_scent', '느긋한 향기 물약', '휴식 구석에 은은한 향을 오래 남겨요.', ['aromaleaf', 'tear', 'web'], 39,
      useLimit: '향을 원할 때만 써요. 다른 사람의 마음을 강제로 바꾸지 않아요.', unlockResidentId: 'mina'),
  Potion('pathlight', '길표지의 빛 물약', '표지판에 붙는 약한 빛으로 밤길을 안내해요.', ['mushroom', 'resin', 'moon'], 43,
      useLimit: '햇빛을 대신하거나 영원히 빛나지는 않아요.', unlockResidentId: 'ellie'),
  Potion('clearvoice', '또렷한 목소리 물약', '부드러운 공명으로 작은 목소리를 전달해요.', ['reed', 'tear', 'petal'], 41,
      useLimit: '목소리를 복제하거나 다른 사람을 강제로 설득하지 않아요.', unlockResidentId: 'nari'),
];

Potion potionById(String id) => potions.firstWhere((p) => p.id == id);
