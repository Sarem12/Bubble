import 'bubble_emoji.dart';
import 'system_emoji_registry.dart';

/// Database of standard emojis and curated animated specials
class EmojiData {
  static final List<BubbleEmoji> _unicodeEmojis = [
    // ------------------------------------------------------------------------
    // SMILEYS & EMOTION
    // ------------------------------------------------------------------------
    BubbleEmoji(
      code: '😂',
      name: 'Face with Tears of Joy',
      category: EmojiCategory.smileys,
      keywords: ['laugh', 'cry', 'happy', 'tears', 'lol', 'funny', 'haha'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(
      code: '🤣',
      name: 'Rolling on the Floor Laughing',
      category: EmojiCategory.smileys,
      keywords: ['rofl', 'laugh', 'lol', 'funny'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(
      code: '😊',
      name: 'Smiling Face with Smiling Eyes',
      category: EmojiCategory.smileys,
      keywords: ['smile', 'happy', 'blush', 'kind'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '🥰',
      name: 'Smiling Face with Hearts',
      category: EmojiCategory.smileys,
      keywords: ['love', 'crush', 'adore', 'hearts', 'affection'],
      isAnimated: true,
      animationType: EmojiAnimationType.heartbeat,
    ),
    BubbleEmoji(
      code: '😍',
      name: 'Heart Eyes',
      category: EmojiCategory.smileys,
      keywords: ['love', 'crush', 'heart', 'adore', 'infatuation'],
      isAnimated: true,
      animationType: EmojiAnimationType.heartbeat,
    ),
    BubbleEmoji(
      code: '🤩',
      name: 'Star-Struck',
      category: EmojiCategory.smileys,
      keywords: ['star', 'eyes', 'excited', 'wow', 'famous'],
      isAnimated: true,
      animationType: EmojiAnimationType.sparkle,
    ),
    BubbleEmoji(
      code: '😎',
      name: 'Smiling Face with Sunglasses',
      category: EmojiCategory.smileys,
      keywords: ['cool', 'shades', 'confident', 'sun'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(
      code: '🥳',
      name: 'Partying Face',
      category: EmojiCategory.smileys,
      keywords: ['party', 'celebrate', 'hat', 'birthday', 'horn'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(
      code: '😮',
      name: 'Face with Open Mouth',
      category: EmojiCategory.smileys,
      keywords: ['surprise', 'wow', 'shock', 'omg'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '🤯',
      name: 'Exploding Head',
      category: EmojiCategory.smileys,
      keywords: ['mind blown', 'shock', 'brain', 'explode'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '😢',
      name: 'Crying Face',
      category: EmojiCategory.smileys,
      keywords: ['sad', 'cry', 'tear', 'depressed'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(
      code: '😭',
      name: 'Loudly Crying Face',
      category: EmojiCategory.smileys,
      keywords: ['sad', 'bawling', 'tears', 'crying'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(
      code: '💀',
      name: 'Skull',
      category: EmojiCategory.smileys,
      keywords: ['dead', 'skeleton', 'dying', 'funny'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(
      code: '🥺',
      name: 'Pleading Face',
      category: EmojiCategory.smileys,
      keywords: ['plead', 'puppy eyes', 'cute', 'beg'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '😜',
      name: 'Winking Face with Tongue',
      category: EmojiCategory.smileys,
      keywords: ['wink', 'tongue', 'playful', 'joke'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(code: '😀', name: 'Grinning Face', category: EmojiCategory.smileys, keywords: ['happy', 'smile']),
    BubbleEmoji(code: '😃', name: 'Grinning Face with Big Eyes', category: EmojiCategory.smileys, keywords: ['smile', 'joy']),
    BubbleEmoji(code: '😄', name: 'Grinning Face with Smiling Eyes', category: EmojiCategory.smileys, keywords: ['laugh']),
    BubbleEmoji(code: '😁', name: 'Beaming Face', category: EmojiCategory.smileys, keywords: ['grin']),
    BubbleEmoji(code: '😆', name: 'Grinning Squinting Face', category: EmojiCategory.smileys, keywords: ['haha']),
    BubbleEmoji(code: '😅', name: 'Grinning Face with Sweat', category: EmojiCategory.smileys, keywords: ['relief', 'whew']),
    BubbleEmoji(code: '😇', name: 'Smiling Face with Halo', category: EmojiCategory.smileys, keywords: ['angel', 'innocent']),
    BubbleEmoji(code: '🙃', name: 'Upside-Down Face', category: EmojiCategory.smileys, keywords: ['sarcasm', 'silly']),
    BubbleEmoji(code: '😉', name: 'Winking Face', category: EmojiCategory.smileys, keywords: ['wink']),
    BubbleEmoji(code: '😌', name: 'Relieved Face', category: EmojiCategory.smileys, keywords: ['calm', 'peace']),
    BubbleEmoji(code: '😏', name: 'Smirking Face', category: EmojiCategory.smileys, keywords: ['smirk', 'flirt']),
    BubbleEmoji(code: '😒', name: 'Unamused Face', category: EmojiCategory.smileys, keywords: ['bored', 'unhappy']),
    BubbleEmoji(code: '🙄', name: 'Face with Rolling Eyes', category: EmojiCategory.smileys, keywords: ['eyeroll']),
    BubbleEmoji(code: '😬', name: 'Grimacing Face', category: EmojiCategory.smileys, keywords: ['awkward', 'nervous']),
    BubbleEmoji(code: '🤥', name: 'Lying Face', category: EmojiCategory.smileys, keywords: ['liar', 'pinocchio']),
    BubbleEmoji(code: '😴', name: 'Sleeping Face', category: EmojiCategory.smileys, keywords: ['sleep', 'zzz', 'tired']),
    BubbleEmoji(code: '😷', name: 'Face with Medical Mask', category: EmojiCategory.smileys, keywords: ['sick', 'mask']),
    BubbleEmoji(code: '🤒', name: 'Face with Thermometer', category: EmojiCategory.smileys, keywords: ['fever', 'ill']),
    BubbleEmoji(code: '🤢', name: 'Nauseated Face', category: EmojiCategory.smileys, keywords: ['gross', 'disgust']),
    BubbleEmoji(code: '🤮', name: 'Face Vomiting', category: EmojiCategory.smileys, keywords: ['puke', 'vomit']),
    BubbleEmoji(code: '🥵', name: 'Hot Face', category: EmojiCategory.smileys, keywords: ['hot', 'sweat', 'summer']),
    BubbleEmoji(code: '🥶', name: 'Cold Face', category: EmojiCategory.smileys, keywords: ['freeze', 'ice', 'winter']),
    BubbleEmoji(code: '😱', name: 'Face Screaming in Fear', category: EmojiCategory.smileys, keywords: ['scared', 'scream']),
    BubbleEmoji(code: '🥱', name: 'Yawning Face', category: EmojiCategory.smileys, keywords: ['yawn', 'sleepy']),
    BubbleEmoji(code: '😤', name: 'Face with Steam From Nose', category: EmojiCategory.smileys, keywords: ['triumph', 'proud']),
    BubbleEmoji(code: '😡', name: 'Pouting Face', category: EmojiCategory.smileys, keywords: ['angry', 'mad', 'rage']),
    BubbleEmoji(code: '😠', name: 'Angry Face', category: EmojiCategory.smileys, keywords: ['annoyed']),
    BubbleEmoji(code: '🤫', name: 'Shushing Face', category: EmojiCategory.smileys, keywords: ['quiet', 'secret']),
    BubbleEmoji(code: '🤔', name: 'Thinking Face', category: EmojiCategory.smileys, keywords: ['think', 'hmm', 'curious']),
    BubbleEmoji(code: '🤐', name: 'Zipper-Mouth Face', category: EmojiCategory.smileys, keywords: ['silent', 'zip']),
    BubbleEmoji(code: '🤨', name: 'Face with Raised Eyebrow', category: EmojiCategory.smileys, keywords: ['skeptical', 'doubt']),
    BubbleEmoji(code: '😐', name: 'Neutral Face', category: EmojiCategory.smileys, keywords: ['meh']),
    BubbleEmoji(code: '😑', name: 'Expressionless Face', category: EmojiCategory.smileys, keywords: ['blank']),
    BubbleEmoji(code: '😶', name: 'Face Without Mouth', category: EmojiCategory.smileys, keywords: ['speechless']),
    BubbleEmoji(code: '🤡', name: 'Clown Face', category: EmojiCategory.smileys, keywords: ['clown', 'joke']),
    BubbleEmoji(code: '👻', name: 'Ghost', category: EmojiCategory.smileys, keywords: ['spooky', 'halloween']),
    BubbleEmoji(code: '👽', name: 'Alien', category: EmojiCategory.smileys, keywords: ['ufo', 'space']),
    BubbleEmoji(code: '🤖', name: 'Robot', category: EmojiCategory.smileys, keywords: ['bot', 'tech']),

    // ------------------------------------------------------------------------
    // GESTURES & HANDS
    // ------------------------------------------------------------------------
    BubbleEmoji(
      code: '👍',
      name: 'Thumbs Up',
      category: EmojiCategory.gestures,
      keywords: ['like', 'yes', 'ok', 'good', 'agree', 'approve'],
      isAnimated: true,
      animationType: EmojiAnimationType.bounce,
    ),
    BubbleEmoji(
      code: '👎',
      name: 'Thumbs Down',
      category: EmojiCategory.gestures,
      keywords: ['dislike', 'no', 'bad', 'disapprove'],
      isAnimated: true,
      animationType: EmojiAnimationType.bounce,
    ),
    BubbleEmoji(
      code: '👏',
      name: 'Clapping Hands',
      category: EmojiCategory.gestures,
      keywords: ['applause', 'bravo', 'congrats', 'cheer'],
      isAnimated: true,
      animationType: EmojiAnimationType.bounce,
    ),
    BubbleEmoji(
      code: '🙌',
      name: 'Raising Hands',
      category: EmojiCategory.gestures,
      keywords: ['praise', 'celebrate', 'hooray', 'yay'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '🤝',
      name: 'Handshake',
      category: EmojiCategory.gestures,
      keywords: ['deal', 'agreement', 'partner', 'friendship'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '✌️',
      name: 'Victory Hand',
      category: EmojiCategory.gestures,
      keywords: ['peace', 'v', 'victory'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(
      code: '🤞',
      name: 'Crossed Fingers',
      category: EmojiCategory.gestures,
      keywords: ['luck', 'hope', 'wish'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(
      code: '🤟',
      name: 'Love-You Gesture',
      category: EmojiCategory.gestures,
      keywords: ['ily', 'rock', 'love'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '🤘',
      name: 'Sign of the Horns',
      category: EmojiCategory.gestures,
      keywords: ['rock', 'metal'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(
      code: '🤙',
      name: 'Call Me Hand',
      category: EmojiCategory.gestures,
      keywords: ['shaka', 'hang loose', 'call'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(code: '👌', name: 'OK Hand', category: EmojiCategory.gestures, keywords: ['perfect', 'okay']),
    BubbleEmoji(code: '🤌', name: 'Pinched Fingers', category: EmojiCategory.gestures, keywords: ['italian', 'gesture']),
    BubbleEmoji(code: '🤏', name: 'Pinching Hand', category: EmojiCategory.gestures, keywords: ['tiny', 'little bit']),
    BubbleEmoji(code: '👋', name: 'Waving Hand', category: EmojiCategory.gestures, keywords: ['hello', 'hi', 'bye']),
    BubbleEmoji(code: '✋', name: 'Raised Hand', category: EmojiCategory.gestures, keywords: ['stop', 'high five']),
    BubbleEmoji(code: '🖐️', name: 'Hand with Fingers Splayed', category: EmojiCategory.gestures, keywords: ['five']),
    BubbleEmoji(code: '👊', name: 'Oncoming Fist', category: EmojiCategory.gestures, keywords: ['fist bump', 'punch']),
    BubbleEmoji(code: '🤛', name: 'Left-Facing Fist', category: EmojiCategory.gestures, keywords: ['bump']),
    BubbleEmoji(code: '🤜', name: 'Right-Facing Fist', category: EmojiCategory.gestures, keywords: ['bump']),
    BubbleEmoji(code: '🙏', name: 'Folded Hands', category: EmojiCategory.gestures, keywords: ['pray', 'please', 'thanks', 'namaste']),
    BubbleEmoji(code: '💪', name: 'Flexed Biceps', category: EmojiCategory.gestures, keywords: ['strong', 'muscle', 'power', 'gym']),
    BubbleEmoji(code: '🤳', name: 'Selfie', category: EmojiCategory.gestures, keywords: ['phone', 'photo']),

    // ------------------------------------------------------------------------
    // HEARTS & AFFECTION
    // ------------------------------------------------------------------------
    BubbleEmoji(
      code: '❤️',
      name: 'Red Heart',
      category: EmojiCategory.hearts,
      keywords: ['love', 'like', 'romance', 'valentine', 'favorite'],
      isAnimated: true,
      animationType: EmojiAnimationType.heartbeat,
    ),
    BubbleEmoji(
      code: '💖',
      name: 'Sparkling Heart',
      category: EmojiCategory.hearts,
      keywords: ['love', 'sparkle', 'shine', 'special'],
      isAnimated: true,
      animationType: EmojiAnimationType.heartbeat,
    ),
    BubbleEmoji(
      code: '💗',
      name: 'Growing Heart',
      category: EmojiCategory.hearts,
      keywords: ['pulse', 'expanding', 'love'],
      isAnimated: true,
      animationType: EmojiAnimationType.heartbeat,
    ),
    BubbleEmoji(
      code: '💓',
      name: 'Beating Heart',
      category: EmojiCategory.hearts,
      keywords: ['thump', 'heartbeat', 'alive'],
      isAnimated: true,
      animationType: EmojiAnimationType.heartbeat,
    ),
    BubbleEmoji(
      code: '💞',
      name: 'Revolving Hearts',
      category: EmojiCategory.hearts,
      keywords: ['spin', 'revolving', 'together'],
      isAnimated: true,
      animationType: EmojiAnimationType.spin,
    ),
    BubbleEmoji(
      code: '💕',
      name: 'Two Hearts',
      category: EmojiCategory.hearts,
      keywords: ['couple', 'sweet', 'hearts'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '💘',
      name: 'Heart with Arrow',
      category: EmojiCategory.hearts,
      keywords: ['cupid', 'crush', 'struck'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '💝',
      name: 'Heart with Ribbon',
      category: EmojiCategory.hearts,
      keywords: ['gift', 'present', 'valentine'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '💔',
      name: 'Broken Heart',
      category: EmojiCategory.hearts,
      keywords: ['breakup', 'sad', 'heartbroken'],
      isAnimated: true,
      animationType: EmojiAnimationType.wobble,
    ),
    BubbleEmoji(code: '🧡', name: 'Orange Heart', category: EmojiCategory.hearts, keywords: ['friendship']),
    BubbleEmoji(code: '💛', name: 'Yellow Heart', category: EmojiCategory.hearts, keywords: ['warmth', 'sunshine']),
    BubbleEmoji(code: '💚', name: 'Green Heart', category: EmojiCategory.hearts, keywords: ['nature', 'envy']),
    BubbleEmoji(code: '💙', name: 'Blue Heart', category: EmojiCategory.hearts, keywords: ['loyalty', 'peace']),
    BubbleEmoji(code: '💜', name: 'Purple Heart', category: EmojiCategory.hearts, keywords: ['glamour', 'royalty']),
    BubbleEmoji(code: '🤎', name: 'Brown Heart', category: EmojiCategory.hearts, keywords: ['earth']),
    BubbleEmoji(code: '🖤', name: 'Black Heart', category: EmojiCategory.hearts, keywords: ['dark', 'goth']),
    BubbleEmoji(code: '🤍', name: 'White Heart', category: EmojiCategory.hearts, keywords: ['pure']),
    BubbleEmoji(code: '🩷', name: 'Pink Heart', category: EmojiCategory.hearts, keywords: ['cute']),
    BubbleEmoji(code: '🩵', name: 'Light Blue Heart', category: EmojiCategory.hearts, keywords: ['sky']),
    BubbleEmoji(code: '🩶', name: 'Grey Heart', category: EmojiCategory.hearts, keywords: ['silver']),

    // ------------------------------------------------------------------------
    // REACTIONS & POPULAR
    // ------------------------------------------------------------------------
    BubbleEmoji(
      code: '🔥',
      name: 'Fire',
      category: EmojiCategory.reactions,
      keywords: ['lit', 'hot', 'flame', 'hype', 'trending', 'awesome'],
      isAnimated: true,
      animationType: EmojiAnimationType.flicker,
    ),
    BubbleEmoji(
      code: '🎉',
      name: 'Party Popper',
      category: EmojiCategory.reactions,
      keywords: ['celebration', 'tada', 'congrats', 'party'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '✨',
      name: 'Sparkles',
      category: EmojiCategory.reactions,
      keywords: ['clean', 'magic', 'glitter', 'shine', 'special'],
      isAnimated: true,
      animationType: EmojiAnimationType.sparkle,
    ),
    BubbleEmoji(
      code: '🚀',
      name: 'Rocket',
      category: EmojiCategory.reactions,
      keywords: ['to the moon', 'launch', 'blast', 'fast'],
      isAnimated: true,
      animationType: EmojiAnimationType.bounce,
    ),
    BubbleEmoji(
      code: '💯',
      name: 'Hundred Points',
      category: EmojiCategory.reactions,
      keywords: ['100', 'perfect', 'keep it real', 'full score'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(
      code: '⚡',
      name: 'High Voltage',
      category: EmojiCategory.reactions,
      keywords: ['lightning', 'fast', 'shock', 'electric', 'power'],
      isAnimated: true,
      animationType: EmojiAnimationType.flicker,
    ),
    BubbleEmoji(
      code: '🌟',
      name: 'Glowing Star',
      category: EmojiCategory.reactions,
      keywords: ['gold', 'twinkle', 'achievement', 'super'],
      isAnimated: true,
      animationType: EmojiAnimationType.sparkle,
    ),
    BubbleEmoji(
      code: '🎯',
      name: 'Bullseye',
      category: EmojiCategory.reactions,
      keywords: ['target', 'hit', 'direct', 'accuracy'],
      isAnimated: true,
      animationType: EmojiAnimationType.pulse,
    ),
    BubbleEmoji(code: '💎', name: 'Gem Stone', category: EmojiCategory.reactions, keywords: ['diamond', 'valuable']),
    BubbleEmoji(code: '🏆', name: 'Trophy', category: EmojiCategory.reactions, keywords: ['winner', 'champion', 'first']),
    BubbleEmoji(code: '👑', name: 'Crown', category: EmojiCategory.reactions, keywords: ['king', 'queen', 'royalty', 'boss']),
    BubbleEmoji(code: '🍿', name: 'Popcorn', category: EmojiCategory.reactions, keywords: ['movie', 'drama', 'watching']),
    BubbleEmoji(code: '👀', name: 'Eyes', category: EmojiCategory.reactions, keywords: ['look', 'see', 'watching', 'curious']),
    BubbleEmoji(code: '💡', name: 'Light Bulb', category: EmojiCategory.reactions, keywords: ['idea', 'smart', 'bright']),
    BubbleEmoji(code: '💣', name: 'Bomb', category: EmojiCategory.reactions, keywords: ['boom', 'explosive']),
    BubbleEmoji(code: '💥', name: 'Collision', category: EmojiCategory.reactions, keywords: ['pow', 'impact']),

    // ------------------------------------------------------------------------
    // FOOD & DRINK
    // ------------------------------------------------------------------------
    BubbleEmoji(code: '🍕', name: 'Pizza', category: EmojiCategory.food, keywords: ['cheese', 'slice']),
    BubbleEmoji(code: '🍔', name: 'Burger', category: EmojiCategory.food, keywords: ['cheeseburger', 'fast food']),
    BubbleEmoji(code: '🍟', name: 'French Fries', category: EmojiCategory.food, keywords: ['fries', 'potatoes']),
    BubbleEmoji(code: '🌮', name: 'Taco', category: EmojiCategory.food, keywords: ['mexican']),
    BubbleEmoji(code: '🍣', name: 'Sushi', category: EmojiCategory.food, keywords: ['japanese', 'fish']),
    BubbleEmoji(code: '🍩', name: 'Doughnut', category: EmojiCategory.food, keywords: ['donut', 'sweet']),
    BubbleEmoji(code: '🍦', name: 'Soft Ice Cream', category: EmojiCategory.food, keywords: ['dessert', 'summer']),
    BubbleEmoji(code: '🎂', name: 'Birthday Cake', category: EmojiCategory.food, keywords: ['cake', 'celebration']),
    BubbleEmoji(code: '☕', name: 'Hot Beverage', category: EmojiCategory.food, keywords: ['coffee', 'tea', 'cafe']),
    BubbleEmoji(code: '🧋', name: 'Bubble Tea', category: EmojiCategory.food, keywords: ['boba', 'tea', 'bubble']),
    BubbleEmoji(code: '🍻', name: 'Clinking Beer Mugs', category: EmojiCategory.food, keywords: ['cheers', 'drink']),
    BubbleEmoji(code: '🍷', name: 'Wine Glass', category: EmojiCategory.food, keywords: ['drink', 'alcohol']),

    // ------------------------------------------------------------------------
    // ACTIVITIES & SPORTS
    // ------------------------------------------------------------------------
    BubbleEmoji(code: '⚽', name: 'Soccer Ball', category: EmojiCategory.activities, keywords: ['football', 'sport']),
    BubbleEmoji(code: '🏀', name: 'Basketball', category: EmojiCategory.activities, keywords: ['hoops', 'nba']),
    BubbleEmoji(code: '🏈', name: 'American Football', category: EmojiCategory.activities, keywords: ['nfl', 'sport']),
    BubbleEmoji(code: '🎾', name: 'Tennis', category: EmojiCategory.activities, keywords: ['ball', 'court']),
    BubbleEmoji(code: '🎮', name: 'Video Game', category: EmojiCategory.activities, keywords: ['controller', 'gaming']),
    BubbleEmoji(code: '🎲', name: 'Game Die', category: EmojiCategory.activities, keywords: ['dice', 'board game', 'roll']),
    BubbleEmoji(code: '🎸', name: 'Guitar', category: EmojiCategory.activities, keywords: ['music', 'rock', 'instrument']),
    BubbleEmoji(code: '🎧', name: 'Headphone', category: EmojiCategory.activities, keywords: ['music', 'audio', 'listen']),

    // ------------------------------------------------------------------------
    // OBJECTS & PLACES
    // ------------------------------------------------------------------------
    BubbleEmoji(code: '📱', name: 'Mobile Phone', category: EmojiCategory.objects, keywords: ['smartphone', 'cell']),
    BubbleEmoji(code: '💻', name: 'Laptop', category: EmojiCategory.objects, keywords: ['computer', 'code', 'tech']),
    BubbleEmoji(code: '📷', name: 'Camera', category: EmojiCategory.objects, keywords: ['photo', 'picture']),
    BubbleEmoji(code: '🚗', name: 'Automobile', category: EmojiCategory.objects, keywords: ['car', 'drive', 'trip']),
    BubbleEmoji(code: '✈️', name: 'Airplane', category: EmojiCategory.objects, keywords: ['travel', 'flight']),
    BubbleEmoji(code: '🏝️', name: 'Desert Island', category: EmojiCategory.objects, keywords: ['beach', 'vacation']),

    // ------------------------------------------------------------------------
    // SYMBOLS
    // ------------------------------------------------------------------------
    BubbleEmoji(code: '✔️', name: 'Check Mark', category: EmojiCategory.symbols, keywords: ['done', 'yes', 'verified']),
    BubbleEmoji(code: '❌', name: 'Cross Mark', category: EmojiCategory.symbols, keywords: ['no', 'wrong', 'cancel']),
    BubbleEmoji(code: '⚠️', name: 'Warning', category: EmojiCategory.symbols, keywords: ['caution', 'alert']),
    BubbleEmoji(code: '❓', name: 'Question Mark', category: EmojiCategory.symbols, keywords: ['what', 'help', 'confused']),
    BubbleEmoji(code: '❗', name: 'Exclamation Mark', category: EmojiCategory.symbols, keywords: ['important', 'alert']),
    BubbleEmoji(code: '♾️', name: 'Infinity', category: EmojiCategory.symbols, keywords: ['forever', 'infinite']),
  ];

  /// Get all emojis belonging to a category
  static List<BubbleEmoji> getByCategory(EmojiCategory category) {
    if (category == EmojiCategory.system) {
      return SystemEmojiRegistry.allSystemEmojis;
    }
    if (category == EmojiCategory.animated) {
      return getAnimatedEmojis();
    }
    return _unicodeEmojis.where((e) => e.category == category).toList();
  }

  /// Get curated animated emojis (combining system animated + unicode animated)
  static List<BubbleEmoji> getAnimatedEmojis() {
    final systemAnimated =
        SystemEmojiRegistry.allSystemEmojis.where((e) => e.isAnimated).toList();
    final unicodeAnimated =
        _unicodeEmojis.where((e) => e.isAnimated).toList();
    return [...systemAnimated, ...unicodeAnimated];
  }

  /// Retrieve all emojis in the system
  static List<BubbleEmoji> getAllEmojis() {
    return [...SystemEmojiRegistry.allSystemEmojis, ..._unicodeEmojis];
  }

  /// Search across all emojis (system + unicode)
  static List<BubbleEmoji> search(String query) {
    final clean = query.toLowerCase().trim();
    if (clean.isEmpty) return getAllEmojis();

    // Check system emojis first
    final systemMatches = SystemEmojiRegistry.search(clean);

    // Search unicode emojis
    final unicodeMatches = _unicodeEmojis.where((emoji) {
      if (emoji.name.toLowerCase().contains(clean)) return true;
      if (emoji.code == clean) return true;
      return emoji.keywords.any((k) => k.toLowerCase().contains(clean));
    }).toList();

    return [...systemMatches, ...unicodeMatches];
  }

  /// Lookup emoji by its code (unicode or system)
  static BubbleEmoji? findByCode(String code) {
    final clean = code.trim();
    if (SystemEmojiRegistry.isSystemEmoji(clean)) {
      return SystemEmojiRegistry.get(clean);
    }
    try {
      final emoji = _unicodeEmojis.firstWhere((e) => e.code == clean);
      return emoji.copyWith(
        isAnimated: true,
        animationType: emoji.animationType == EmojiAnimationType.none
            ? _defaultAnimForCode(clean)
            : emoji.animationType,
      );
    } catch (_) {
      return BubbleEmoji(
        code: clean,
        name: clean,
        category: EmojiCategory.smileys,
        isAnimated: true,
        animationType: _defaultAnimForCode(clean),
      );
    }
  }

  /// Automatically map any emoji to an expressive animation type
  static EmojiAnimationType _defaultAnimForCode(String code) {
    if (code.contains('❤️') ||
        code.contains('💖') ||
        code.contains('💕') ||
        code.contains('💗') ||
        code.contains('💓') ||
        code.contains('💘') ||
        code.contains('💞') ||
        code.contains('💟') ||
        code.contains('🖤') ||
        code.contains('🤍') ||
        code.contains('🤎') ||
        code.contains('💜') ||
        code.contains('💙') ||
        code.contains('💚') ||
        code.contains('💛') ||
        code.contains('🧡') ||
        code.contains('🩷') ||
        code.contains('🩵') ||
        code.contains('🩶') ||
        code.contains('🥰') ||
        code.contains('😍')) {
      return EmojiAnimationType.heartbeat;
    }
    if (code.contains('🔥') ||
        code.contains('💥') ||
        code.contains('⚡') ||
        code.contains('🧨') ||
        code.contains('🌋')) {
      return EmojiAnimationType.flicker;
    }
    if (code.contains('😂') ||
        code.contains('🤣') ||
        code.contains('😜') ||
        code.contains('🤪') ||
        code.contains('🥳') ||
        code.contains('😎') ||
        code.contains('💀') ||
        code.contains('🙃') ||
        code.contains('👻') ||
        code.contains('🤡')) {
      return EmojiAnimationType.wobble;
    }
    if (code.contains('👍') ||
        code.contains('👎') ||
        code.contains('👏') ||
        code.contains('🙌') ||
        code.contains('🚀') ||
        code.contains('🎉') ||
        code.contains('🏀') ||
        code.contains('⚽') ||
        code.contains('🏆') ||
        code.contains('🎯')) {
      return EmojiAnimationType.bounce;
    }
    if (code.contains('✨') ||
        code.contains('⭐') ||
        code.contains('🌟') ||
        code.contains('💎') ||
        code.contains('💫') ||
        code.contains('🤩')) {
      return EmojiAnimationType.sparkle;
    }
    if (code.contains('🌀') ||
        code.contains('🌌') ||
        code.contains('🪐') ||
        code.contains('🔄') ||
        code.contains('💫')) {
      return EmojiAnimationType.spin;
    }
    return EmojiAnimationType.pulse;
  }
}
