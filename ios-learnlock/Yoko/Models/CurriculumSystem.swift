//
//  CurriculumSystem.swift
//  Yoko
//
//  Improved sample questions — richer content, stronger grade differentiation,
//  more visual/interactive variety across all templates.
//

import Foundation

nonisolated enum GradeBand: String, CaseIterable, Hashable, Codable { case kindergarten = "Kindergarten", grade1 = "Grade 1", grade2 = "Grade 2", grade3 = "Grade 3" }
nonisolated enum DifficultyMode: String, CaseIterable, Hashable, Codable { case easy = "Easy", balanced = "Balanced", adaptive = "Adaptive" }
nonisolated enum CurriculumSubject: String, CaseIterable, Hashable, Codable { case math = "Math", english = "English" }

nonisolated struct CurriculumComponent: Identifiable, Hashable, Codable {
    var id: String { name }
    let name: String
    let purpose: String
    let visualDescription: String
    let supportedSkills: [String]
    let supportedInteractions: [String]
    let difficultyScaling: String
    let requiredDataFields: [String]
}

nonisolated struct CurriculumTemplate: Identifiable, Hashable, Codable {
    var id: String { templateName }
    let templateName: String
    let associatedComponent: String
    let learningGoal: String
    let supportedGradeBands: [GradeBand]
    let promptPattern: String
    let supportedVisualPacks: [String]
    let interactionType: String
    let hintBehavior: String
    let difficultyNotes: String
    let sampleQuestion: NormalizedQuestion
}

nonisolated struct NormalizedQuestion: Identifiable, Hashable, Codable {
    let id: String
    let subject: CurriculumSubject
    let skill: String
    let component: String
    let templateType: String
    let prompt: String
    let directions: String
    let visualSource: String
    let questionContent: [String: String]
    let answerChoices: [String]
    let correctAnswer: String
    let interactionType: String
    let difficulty: DifficultyMode
    let hintType: String
    let feedbackCorrect: String
    let feedbackIncorrect: String
    let gradeBand: GradeBand?
    let estimatedSeconds: Int?
    let masteryTag: String?
    let curriculumUnit: String?
    let sessionGoal: String?
    let unlockContext: String?
    let questionSeed: String?
}

nonisolated enum CurriculumSystem {
    static let systemRules = "Skill-driven, not grade-labeled. Kindergarten-Grade 3 define defaults, while reusable skill groups, visual components, and templates drive generation. Generation is separate from rendering: generators output NormalizedQuestion; UI renderers consume component, visualSource, questionContent, choices, and interactionType. Difficulty modes: Easy uses smaller sets and stronger hints; Balanced uses grade defaults; Adaptive adjusts ranges, distractor closeness, and hint timing from performance without changing components. Unlock sessions stay coherent: 3 related questions earn 15 minutes, 5 related questions earn 20 minutes."

    static let mathVisualPacks = ["fruit_pack: apple, banana, orange, grapes, strawberry, watermelon", "animal_pack: dog, cat, bear, frog, turtle, fish, rabbit", "food_pack: cookie, pizza, carrot, cupcake, corn", "fun_pack: ball, balloon, toy car, gift, kite, star", "school_pack: pencil, crayon, book, ruler, paperclip, backpack", "shape_pack: circle, square, triangle, rectangle, star, diamond, oval, heart; filled, outline, size variation, color variation", "symbol_support_pack: numbers 0-1000, plus, minus, multiply, divide, greater/less/equal, arrows, tallies, fraction labels, blanks, selected/correct/incorrect/disabled/faded states, highlighted hints, fills, guide overlays, ten-frame dots, dice dots, ticks, buckets, fraction bars, clocks, digital cards"]
    static let englishVisualPacks = ["animal_vocab_pack: dog, cat, bear, frog, lion, turtle, fish, bird, rabbit, duck", "food_vocab_pack: apple, pizza, cookie, banana, carrot, corn, milk, bread, cupcake", "school_vocab_pack: book, pencil, ruler, backpack, paper, crayon, scissors, desk", "daily_routine_pack: bed, toothbrush, bus, lunchbox, shoes, clock, bath, pajamas", "places_pack: house, school, park, store, tree, road, playground, library", "emotion_pack: happy, sad, sleepy, excited, surprised, scared, proud", "letter_pack: uppercase A-Z, lowercase a-z", "word_packs: sight_words, cvc, short_vowel, word_family, common_school_words, tricky_words, simple_verbs, simple_nouns", "symbol_support_pack: punctuation, arrows, blanks, underlines, dividers, reorder handles, connectors, separators, labels, answer slots, selected/correct/incorrect states, word chips, letter chips, hint highlights, placeholders, focus outlines, fills"]

    static let mathHintRules: [String: String] = ["counting":"Pulse items left-to-right and show count badges.", "more/less":"Pair off objects and leave extras highlighted.", "addition":"Animate groups joining, then count all.", "subtraction":"Fade removed items while preserving the starting set.", "missing numbers":"Show a number bond or ghost chip in the blank.", "number line":"Draw jump arcs and highlight landing ticks.", "make ten":"Ghost-fill empty ten-frame slots.", "skip counting":"Highlight equal interval jumps.", "multiplication":"Glow rows or columns one at a time.", "division":"Auto-share one item per bucket in rounds.", "patterns":"Bracket the repeating unit and outline the blank.", "fractions":"Label filled parts over total parts.", "time":"Glow hour hand first, then minute hand."]
    static let englishHintRules: [String: String] = ["letter recognition":"Pulse target letter shape.", "uppercase-lowercase":"Use matching outlines on same letter forms.", "beginning sounds":"Highlight first letter/sound chunk.", "missing letter":"Show the missing sound position.", "spelling":"Underline tricky or incorrect chunk.", "fill missing letters":"Reveal one chunk or vowel pattern.", "unscramble":"Lock correctly placed letters.", "rhyming":"Highlight shared ending sound.", "vocabulary":"Show emoji/context association.", "word families":"Underline shared rime.", "sentence building":"Show capital-first and punctuation-last anchors.", "sight words":"Spotlight the target word in a strip.", "grammar sorting":"Show category headers with examples.", "punctuation":"Animate sentence voice: question/exclamation/statement.", "reading comprehension":"Highlight evidence in text or emoji strip.", "sequencing":"Show first/next/last placeholders.", "category match":"Preview one correct item per bucket."]

    static let mathComponents: [CurriculumComponent] = [
        c("Emoji Counter Row", "Count tangible objects", "Large emoji counters in rows with faded removed states.", ["counting objects", "addition by counting", "subtraction by taking away"], ["tap to count", "select total", "remove items"], "1-5, 1-10, 1-20, then equal groups.", ["items", "targetCount", "removedCount", "pack"]),
        c("Shape Counter Grid", "Organize quantities", "Colored shapes in grids; filled, outline, selected, and hinted states.", ["compare quantities", "arrays", "area"], ["tap cells", "select group", "drag shapes"], "Increase rows, columns, and mixed attributes.", ["rows", "columns", "shapes", "colors"]),
        c("Number Line", "Reason with jumps", "Ticked line with arrows, labels, and animated jump arcs.", ["missing numbers", "number line jumps", "skip counting"], ["tap tick", "drag arrow", "choose landing number"], "0-10 to 0-1000 with larger intervals.", ["start", "end", "ticks", "jumps"]),
        c("Ten-Frame", "Build make-ten fluency", "Two-by-five frame with orange dots and ghost hint dots.", ["make ten", "ten-frame fluency", "addition within 20"], ["fill dots", "choose missing", "tap frame"], "One frame, two frames, then hidden addends.", ["filled", "target", "emptySlots"]),
        c("Dice or Dot Card", "Subitize", "Rounded cards with dice dots or scattered dots.", ["number recognition", "compare quantities", "even and odd"], ["choose card", "match number", "sort cards"], "Organized dots to scattered higher counts.", ["dotPattern", "value", "layout"]),
        c("Grouping Buckets", "Group or share objects", "Labeled buckets receiving counters by drag or tap.", ["grouping", "division as sharing", "multiplication facts"], ["drag to bucket", "tap distribute", "select group size"], "More buckets, larger totals, then remainders.", ["objects", "bucketCount", "labels"]),
        c("Pattern Row", "Complete patterns", "Sequence of shapes, emojis, or numbers with blanks.", ["simple patterns", "skip counting", "pattern recognition"], ["choose missing", "drag tile", "continue pattern"], "AB to AAB/ABC and numeric rules.", ["sequence", "blankIndex", "choices"]),
        c("Fraction or Fill Bar", "Represent parts of a whole", "Segmented fill bar with fraction labels.", ["fractions basics", "compare fractions"], ["tap segment", "choose label", "fill bar"], "Halves/thirds/fourths to eighths.", ["parts", "filled", "labels"]),
        c("Clock Card", "Read time", "Analog clock paired with digital time cards.", ["hour-only time", "half-hour time", "analog-to-digital time"], ["choose time", "move hands", "match cards"], "Hour, half-hour, then five-minute increments.", ["hour", "minute", "choices"]),
        c("Blank Slot Builder", "Complete equations", "Equation strip with rounded blanks and number chips.", ["missing number equations", "number bonds"], ["drag chip", "tap choice", "fill blank"], "Blank result, missing addend, then missing operator.", ["equation", "blankIndex", "chips"]),
        c("Comparison Card Pair", "Compare values", "Two quantity cards and a center comparison slot.", ["more or less", "compare numbers to 100"], ["choose symbol", "tap larger", "drag comparison"], "Objects to numerals and expressions.", ["leftValue", "rightValue", "comparisonType"]),
        c("Array Builder", "Model multiplication", "Rows and columns of dots/shapes with labels.", ["multiplication arrays", "area as arrays", "division"], ["build array", "select product", "tap rows"], "Small arrays to missing dimensions.", ["rows", "columns", "item"])
    ]

    static let englishComponents: [CurriculumComponent] = [
        c("Letter Tile", "Recognize letters", "Large rounded letter chips with case and sound highlights.", ["letter recognition", "uppercase-lowercase", "beginning sounds"], ["tap tile", "match tile", "drag tile"], "Distinct letters to similar distractors.", ["letters", "target", "caseMode"]),
        c("Word Tile", "Read words", "Word chips with chunk underlines.", ["sight words", "spelling", "word families"], ["tap word", "drag word", "match word"], "CVC to tricky and multisyllable words.", ["words", "target", "chunks"]),
        c("Sentence Strip", "Build sentences", "Horizontal strip of word chips with blanks or reorder handles.", ["sentence building", "punctuation", "grammar sorting"], ["reorder", "fill blank", "choose punctuation"], "Short strips to longer Grade 3 strips.", ["tokens", "blanks", "punctuation"]),
        c("Story Emoji Strip", "Support comprehension", "Emoji sequence above sentence cards.", ["reading comprehension", "sequencing", "vocabulary"], ["choose answer", "reorder events", "match emoji"], "Emoji-supported to text-first.", ["emojis", "text", "question"]),
        c("Matching Card Set", "Connect related items", "Two card columns with connectors.", ["vocabulary matching", "rhyming", "uppercase-lowercase"], ["tap pairs", "draw match", "drag card"], "More pairs and closer meanings.", ["leftCards", "rightCards", "pairs"]),
        c("Grouping Buckets", "Sort language", "Category buckets with word/letter chips.", ["grammar sorting", "category match", "word families"], ["drag to bucket", "tap category", "sort chips"], "Two obvious buckets to three abstract ones.", ["categories", "items", "answers"]),
        c("Blank Slot Builder", "Complete words/sentences", "Text with rounded blanks and chips.", ["missing letter", "fill missing letters", "sentence fill"], ["drag chip", "tap choice", "type short answer"], "Single blanks to whole-word blanks.", ["textWithBlanks", "chips", "answers"]),
        c("Pattern Row", "Language patterns", "Word-family or rhyme chips with blanks.", ["word families", "rhyming", "phonics"], ["choose missing", "continue pattern", "sort rhyme"], "Shared rime to mixed spelling patterns.", ["sequence", "blankIndex", "choices"]),
        c("Choice Card Row", "Quick recognition", "Large answer cards with words, letters, emojis, or punctuation.", ["letter recognition", "sight words", "punctuation choice"], ["tap choice", "eliminate choice"], "More choices and closer distractors.", ["choices", "correct"]),
        c("Sequence Card Row", "Order items", "Draggable cards with placeholders.", ["sequencing", "sentence reorder"], ["drag reorder", "tap swap"], "Three cards to five cards.", ["cards", "correctOrder"]),
        c("Word Builder Tray", "Construct words", "Letter chip tray below empty slots.", ["unscramble word", "CVC words", "spelling"], ["drag letters", "tap build"], "CVC to blends and tricky words.", ["letters", "slots", "answer"]),
        c("Highlight Reader Card", "Guide reading", "Short text card with highlighted chunks or evidence.", ["comprehension", "sight words", "prefix/suffix"], ["tap highlighted answer", "choose meaning"], "Phrase to short paragraph.", ["text", "highlights", "question"])
    ]

    static let mathTemplates: [CurriculumTemplate] = [
        mt("Counting Objects", "Emoji Counter Row", "Count objects", [.kindergarten], "How many {items}?", ["fruit_pack"], "tap_choice", sampleMathQuestions[0]),
        mt("Which Has More or Less", "Comparison Card Pair", "Compare quantities", [.kindergarten, .grade1], "Which has {more/less}?", ["animal_pack"], "tap_card", sampleMathQuestions[1]),
        mt("Addition by Counting", "Emoji Counter Row", "Combine groups", [.kindergarten, .grade1], "{a} + {b} = ?", ["fruit_pack"], "tap_choice", sampleMathQuestions[2]),
        mt("Subtraction by Taking Away", "Emoji Counter Row", "Remove from a set", [.kindergarten, .grade1], "{start} take away {remove}", ["food_pack"], "tap_choice", sampleMathQuestions[3]),
        mt("Missing Number Equation", "Blank Slot Builder", "Find missing value", [.grade1, .grade2], "{a} + __ = {total}", ["symbol_support_pack"], "drag_number_chip", sampleMathQuestions[4]),
        mt("Number Line Jump", "Number Line", "Use jumps", [.grade1, .grade2, .grade3], "Start at {start}; jump {jump}", ["symbol_support_pack"], "tap_tick", sampleMathQuestions[5]),
        mt("Make Ten", "Ten-Frame", "Complete ten", [.kindergarten, .grade1], "How many more make 10?", ["symbol_support_pack"], "tap_choice", sampleMathQuestions[6]),
        mt("Skip Counting Sequence", "Pattern Row", "Continue skip counts", [.grade2, .grade3], "What comes next?", ["symbol_support_pack"], "tap_choice", sampleMathQuestions[7]),
        mt("Multiplication Arrays", "Array Builder", "Rows and columns", [.grade3], "{rows} rows of {columns}", ["shape_pack"], "tap_choice", sampleMathQuestions[8]),
        mt("Division as Sharing", "Grouping Buckets", "Share equally", [.grade3], "Share {total} into {groups}", ["animal_pack"], "drag_to_bucket", sampleMathQuestions[9]),
        mt("Pattern Recognition", "Pattern Row", "Complete visual patterns", [.kindergarten, .grade1, .grade2], "What completes the pattern?", ["shape_pack"], "drag_tile", sampleMathQuestions[10]),
        mt("Fractions", "Fraction or Fill Bar", "Match part to whole", [.grade3], "What fraction is shaded?", ["symbol_support_pack"], "tap_choice", sampleMathQuestions[11]),
        mt("Telling Time", "Clock Card", "Read clocks", [.kindergarten, .grade2, .grade3], "What time is it?", ["symbol_support_pack"], "tap_choice", sampleMathQuestions[12]),
        mt("Compare Numbers", "Comparison Card Pair", "Compare numerals", [.grade1, .grade2], "Choose >, <, or =", ["symbol_support_pack"], "choose_symbol", sampleMathQuestions[13]),
        mt("True or False Math Statement", "Choice Card Row", "Judge statements", [.grade1, .grade2, .grade3], "Is {statement} true?", ["symbol_support_pack"], "tap_choice", sampleMathQuestions[14])
    ]

    static let englishTemplates: [CurriculumTemplate] = [
        et("Letter Recognition", "Letter Tile", "Identify letters", [.kindergarten], "Find {letter}", ["letter_pack"], "tap_tile", sampleEnglishQuestions[0]),
        et("Uppercase-Lowercase Matching", "Matching Card Set", "Match cases", [.kindergarten], "Match {uppercase}", ["letter_pack"], "match_cards", sampleEnglishQuestions[1]),
        et("Beginning Sounds", "Choice Card Row", "Match first sounds", [.kindergarten, .grade1], "Which starts with {sound}?", ["animal_vocab_pack"], "tap_choice", sampleEnglishQuestions[2]),
        et("Missing Letter", "Blank Slot Builder", "Complete word", [.kindergarten, .grade1], "Fill {wordWithBlank}", ["cvc_pack"], "drag_letter_chip", sampleEnglishQuestions[3]),
        et("Choose Correct Spelling", "Choice Card Row", "Recognize spelling", [.grade1, .grade2, .grade3], "Which is correct?", ["common_school_words_pack"], "tap_choice", sampleEnglishQuestions[4]),
        et("Fill Missing Letters", "Blank Slot Builder", "Complete blanks", [.grade1, .grade2], "Fill missing letters", ["short_vowel_pack"], "drag_letter_chips", sampleEnglishQuestions[5]),
        et("Unscramble Word", "Word Builder Tray", "Build word", [.grade1, .grade2, .grade3], "Unscramble", ["cvc_pack"], "drag_reorder", sampleEnglishQuestions[6]),
        et("Rhyming Words", "Pattern Row", "Identify rhymes", [.grade1, .grade2], "Which rhymes?", ["word_family_pack"], "tap_choice", sampleEnglishQuestions[7]),
        et("Vocabulary Matching", "Matching Card Set", "Match word to meaning", [.kindergarten, .grade1, .grade2, .grade3], "Match word and picture", ["food_vocab_pack"], "match_cards", sampleEnglishQuestions[8]),
        et("Word Families", "Pattern Row", "Recognize rimes", [.grade1, .grade2], "Choose the same family", ["word_family_pack"], "tap_choice", sampleEnglishQuestions[9]),
        et("Sentence Building", "Sentence Strip", "Order words", [.grade1, .grade2, .grade3], "Build sentence", ["word_packs"], "drag_reorder", sampleEnglishQuestions[10]),
        et("Sight Word Recognition", "Choice Card Row", "Find sight word", [.kindergarten, .grade1, .grade2, .grade3], "Find {word}", ["sight_words_pack"], "tap_choice", sampleEnglishQuestions[11]),
        et("Grammar Sorting", "Grouping Buckets", "Sort parts of speech", [.grade2, .grade3], "Sort words", ["simple_verbs_pack", "simple_nouns_pack"], "drag_to_bucket", sampleEnglishQuestions[12]),
        et("Punctuation Choice", "Sentence Strip", "Choose punctuation", [.grade1, .grade2, .grade3], "Pick punctuation", ["symbol_support_pack"], "tap_choice", sampleEnglishQuestions[13]),
        et("Reading Comprehension", "Story Emoji Strip", "Answer story question", [.grade2, .grade3], "Read and answer", ["daily_routine_pack"], "tap_choice", sampleEnglishQuestions[14]),
        et("Sequencing", "Sequence Card Row", "Order events", [.kindergarten, .grade1, .grade2, .grade3], "Put in order", ["daily_routine_pack"], "drag_reorder", sampleEnglishQuestions[15]),
        et("Category Match", "Grouping Buckets", "Match categories", [.kindergarten, .grade1, .grade2, .grade3], "Sort by category", ["places_pack", "food_vocab_pack"], "drag_to_bucket", sampleEnglishQuestions[16])
    ]

    // =========================================================
    // MARK: - SAMPLE QUESTION LIBRARY — COUNTS
    // ---------------------------------------------------------
    // These hand-authored, fully-validated samples seed the templates and act
    // as a verified reference set. The truly *infinite* lesson stream is
    // produced procedurally by CurriculumGenerator; this library guarantees a
    // correct exemplar for every template/grade band.
    //
    //   Math   sample questions: 51
    //     Kindergarten: 12  | Grade 1: 14 | Grade 2: 12 | Grade 3: 13
    //   English sample questions: 52
    //     Kindergarten: 12  | Grade 1: 14 | Grade 2: 13 | Grade 3: 13
    // =========================================================

    // =========================================================
    // MARK: - MATH QUESTIONS
    // =========================================================
    // 0  Kindergarten — Counting Objects (small, vivid, concrete)
    // 1  Kindergarten — Which Has More or Less (clear visual gap)
    // 2  Kindergarten — Addition by Counting (tiny numbers, emoji groups)
    // 3  Kindergarten — Subtraction (faded objects, easy removal)
    // 4  Grade 1 — Missing Number Equation (single blank, number bond)
    // 5  Grade 1 — Number Line Jump (short range, positive jump)
    // 6  Grade 1 — Make Ten (ten-frame, 6–9 filled)
    // 7  Grade 2 — Skip Counting (count by 2s)
    // 8  Grade 3 — Multiplication Arrays
    // 9  Grade 3 — Division as Sharing
    // 10 Kindergarten — Pattern Recognition (AB shape pattern)
    // 11 Grade 3 — Fractions (quarters)
    // 12 Grade 2 — Telling Time (half-hour)
    // 13 Grade 2 — Compare Numbers (two-digit)
    // 14 Grade 1 — True or False
    // 15 Grade 2 — Missing Addend (larger numbers)
    // 16 Grade 1 — Number Line (backward jump)
    // 17 Grade 3 — Fractions (thirds)
    // 18 Grade 3 — Telling Time (five-minute)
    // 19 Grade 2 — Skip Counting by 5s
    // 20 Kindergarten — Counting Objects (animals, count to 4)
    // 21 Grade 1 — Addition (word problem scaffold)
    // 22 Grade 3 — Multiplication (missing factor)
    // 23 Grade 2 — Pattern (numeric, growing)
    // 24 Grade 1 — Subtraction (number line visual)
    static let sampleMathQuestions: [NormalizedQuestion] = [

        // 0 — Kindergarten: Counting Objects (fruit, count to 6)
        q(.math, "fruit_counting_6", "counting objects", "Emoji Counter Row", "Counting Objects",
          "How many apples do you see?",
          "Count the apples, then choose the number.",
          "fruit_pack",
          ["items":"🍎 🍎 🍎 🍎 🍎 🍎", "count":"6"],
          ["5","6","7"], "6", .kindergarten),

        // 1 — Kindergarten: Which Has More (clear gap — 4 vs 2)
        q(.math, "more_dogs_vs_cats", "more or less", "Comparison Card Pair", "Which Has More or Less",
          "Which group has MORE animals?",
          "Tap the group with more.",
          "animal_pack",
          ["left":"🐶 🐶 🐶 🐶", "right":"🐱 🐱", "leftLabel":"dogs", "rightLabel":"cats"],
          ["dogs","cats"], "dogs", .kindergarten),

        // 2 — Kindergarten: Addition by Counting (2 + 3)
        q(.math, "addition_2_plus_3", "addition by counting", "Emoji Counter Row", "Addition by Counting",
          "2 bananas + 3 bananas = ?",
          "Count both groups together.",
          "fruit_pack",
          ["left":"🍌 🍌", "right":"🍌 🍌 🍌", "equation":"2 + 3 = __"],
          ["4","5","6"], "5", .kindergarten),

        // 3 — Kindergarten: Subtraction (5 take away 2, faded circles)
        q(.math, "subtraction_5_minus_2", "subtraction by taking away", "Emoji Counter Row", "Subtraction by Taking Away",
          "5 cookies, take away 2. How many are left?",
          "Count the cookies that are not faded.",
          "food_pack",
          ["items":"🍪 🍪 🍪 ◌ ◌", "equation":"5 - 2 = __"],
          ["2","3","4"], "3", .kindergarten),

        // 4 — Grade 1: Missing Number Equation (4 + __ = 9)
        q(.math, "missing_eq_4_plus_blank", "missing number equations", "Blank Slot Builder", "Missing Number Equation",
          "4 + __ = 9",
          "Drag the missing number into the blank.",
          "symbol_support_pack",
          ["equation":"4 + __ = 9", "chips":"3,4,5"],
          ["3","4","5"], "5", .grade1),

        // 5 — Grade 1: Number Line Jump forward (+4 from 6)
        q(.math, "number_line_6_plus4", "number line jumps", "Number Line", "Number Line Jump",
          "Start at 6. Jump forward 4. Where do you land?",
          "Tap the landing number.",
          "symbol_support_pack",
          ["start":"6", "jump":"+4", "range":"0-12"],
          ["9","10","11"], "10", .grade1),

        // 6 — Grade 1: Make Ten (7 filled → 3 more needed)
        q(.math, "make_ten_7", "make ten", "Ten-Frame", "Make Ten",
          "There are 7 dots. How many more make 10?",
          "Look at the empty spaces.",
          "symbol_support_pack",
          ["filled":"7", "empty":"3"],
          ["2","3","4"], "3", .grade1),

        // 7 — Grade 2: Skip Counting by 2s
        q(.math, "skip_count_2s", "skip counting", "Pattern Row", "Pattern Recognition",
          "What comes next: 2, 4, 6, 8, __?",
          "Count by 2s.",
          "symbol_support_pack",
          ["sequence":"2, 4, 6, 8, __"],
          ["9","10","12"], "10", .grade2),

        // 8 — Grade 3: Multiplication Arrays (3 × 4)
        q(.math, "array_3x4", "multiplication arrays", "Array Builder", "Multiplication Arrays",
          "3 rows of 4 stars. How many stars are there?",
          "Count the array or use 3 × 4.",
          "shape_pack",
          ["rows":"3", "columns":"4", "item":"⭐"],
          ["10","12","14"], "12", .grade3),

        // 9 — Grade 3: Division as Sharing (12 fish ÷ 3 bowls)
        q(.math, "division_12_div_3", "division as sharing", "Grouping Buckets", "Division as Sharing",
          "Share 12 fish equally into 3 bowls. How many in each bowl?",
          "Put the same number in every bowl.",
          "animal_pack",
          ["objects":"🐟x12", "buckets":"3"],
          ["3","4","6"], "4", .grade3),

        // 10 — Kindergarten: Pattern Recognition (AB emoji pattern)
        q(.math, "pattern_ab_shapes", "pattern recognition", "Pattern Row", "Pattern Recognition",
          "What comes next? 🔴 🔵 🔴 🔵 __",
          "Choose the missing piece.",
          "shape_pack",
          ["sequence":"🔴, 🔵, 🔴, 🔵, blank"],
          ["🔴","🔵","⭐"], "🔴", .kindergarten),

        // 11 — Grade 3: Fractions — quarters (1/4 shaded)
        q(.math, "fraction_quarter", "fractions basics", "Fraction or Fill Bar", "Fractions",
          "What fraction of the bar is filled?",
          "Choose the matching fraction.",
          "symbol_support_pack",
          ["parts":"4", "filled":"1"],
          ["1/2","1/3","1/4"], "1/4", .grade3),

        // 12 — Grade 2: Telling Time (3:30 on analog clock)
        q(.math, "time_3_30", "telling time", "Clock Card", "Telling Time",
          "What time does the clock show?",
          "Look at the hour and minute hands.",
          "symbol_support_pack",
          ["hour":"3", "minute":"30", "clock":"analog"],
          ["3:00","3:30","6:30"], "3:30", .grade2),

        // 13 — Grade 2: Compare Numbers (42 vs 24)
        q(.math, "compare_42_vs_24", "compare numbers", "Comparison Card Pair", "Compare Numbers",
          "Which number is bigger: 42 or 24?",
          "Tap the larger number.",
          "symbol_support_pack",
          ["left":"42", "right":"24"],
          ["42","24"], "42", .grade2),

        // 14 — Grade 1: True or False (6 + 2 = 9?)
        q(.math, "true_false_6plus2", "true or false", "Choice Card Row", "True or False Math Statement",
          "Is 6 + 2 = 9 true or false?",
          "Choose true or false.",
          "symbol_support_pack",
          ["statement":"6 + 2 = 9"],
          ["True","False"], "False", .grade1),

        // 15 — Grade 2: Missing Addend (larger, __ + 8 = 15)
        q(.math, "missing_eq_blank_plus8", "missing number equations", "Blank Slot Builder", "Missing Number Equation",
          "__ + 8 = 15",
          "Drag the missing number into the blank.",
          "symbol_support_pack",
          ["equation":"__ + 8 = 15", "chips":"5,6,7,8"],
          ["5","6","7","8"], "7", .grade2),

        // 16 — Grade 1: Number Line backward jump (10 − 3)
        q(.math, "number_line_10_minus3", "number line jumps", "Number Line", "Number Line Jump",
          "Start at 10. Jump back 3. Where do you land?",
          "Tap the landing number.",
          "symbol_support_pack",
          ["start":"10", "jump":"-3", "range":"0-12"],
          ["6","7","8"], "7", .grade1),

        // 17 — Grade 3: Fractions — thirds (2/3 shaded)
        q(.math, "fraction_thirds_2", "fractions basics", "Fraction or Fill Bar", "Fractions",
          "What fraction of the bar is shaded?",
          "Choose the matching fraction.",
          "symbol_support_pack",
          ["parts":"3", "filled":"2"],
          ["1/3","2/3","3/3"], "2/3", .grade3),

        // 18 — Grade 3: Telling Time (7:45 on analog clock)
        q(.math, "time_7_45", "telling time", "Clock Card", "Telling Time",
          "What time does the clock show?",
          "Look at both hands carefully.",
          "symbol_support_pack",
          ["hour":"7", "minute":"45", "clock":"analog"],
          ["7:45","8:45","7:15"], "7:45", .grade3),

        // 19 — Grade 2: Skip Counting by 5s
        q(.math, "skip_count_5s", "skip counting", "Pattern Row", "Pattern Recognition",
          "What comes next: 5, 10, 15, 20, __?",
          "Count by 5s.",
          "symbol_support_pack",
          ["sequence":"5, 10, 15, 20, __"],
          ["22","25","30"], "25", .grade2),

        // 20 — Kindergarten: Counting (animals, count to 4)
        q(.math, "animal_count_4", "counting objects", "Emoji Counter Row", "Counting Objects",
          "How many frogs do you see?",
          "Count each frog, then choose.",
          "animal_pack",
          ["items":"🐸 🐸 🐸 🐸", "count":"4"],
          ["3","4","5"], "4", .kindergarten),

        // 21 — Grade 1: Addition word-problem scaffold (3 + 4)
        q(.math, "addition_word_3_plus4", "addition by counting", "Emoji Counter Row", "Addition by Counting",
          "3 dogs and 4 cats are in the park. How many animals in all?",
          "Count all the animals together.",
          "animal_pack",
          ["left":"🐶 🐶 🐶", "right":"🐱 🐱 🐱 🐱", "equation":"3 + 4 = __"],
          ["6","7","8"], "7", .grade1),

        // 22 — Grade 3: Multiplication missing factor (__ × 6 = 18)
        q(.math, "missing_factor_blank_x6", "missing number equations", "Blank Slot Builder", "Missing Number Equation",
          "__ × 6 = 18",
          "Drag the missing number.",
          "symbol_support_pack",
          ["equation":"__ × 6 = 18", "chips":"2,3,4,6"],
          ["2","3","4","6"], "3", .grade3),

        // 23 — Grade 2: Growing numeric pattern (+3 each step)
        q(.math, "pattern_grow_plus3", "pattern recognition", "Pattern Row", "Pattern Recognition",
          "What comes next: 3, 6, 9, 12, __?",
          "Find the rule, then choose.",
          "symbol_support_pack",
          ["sequence":"3, 6, 9, 12, __"],
          ["13","15","14"], "15", .grade2),

        // 24 — Grade 1: Subtraction on a number line (8 − 5)
        q(.math, "number_line_8_minus5", "number line jumps", "Number Line", "Number Line Jump",
          "Start at 8. Jump back 5. Where do you land?",
          "Tap the landing number.",
          "symbol_support_pack",
          ["start":"8", "jump":"-5", "range":"0-12"],
          ["2","3","4"], "3", .grade1),

        // 25 — Kindergarten/Grade 1: Counting/Array (12 frogs as 3×4 grid)
        q(.math, "frog_array_12", "counting objects", "Emoji Counter Row", "Counting Objects",
          "How many frogs do you see?",
          "Count each frog or multiply (4 frogs x 3 frogs)",
          "animal_pack",
          ["items":"🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸 🐸", "count":"12", "columns":"4"],
          ["11","13","12"], "12", .grade1),

        // ----- Expanded Kindergarten -----
        q(.math, "count_strawberries_3", "counting objects", "Emoji Counter Row", "Counting Objects",
          "How many strawberries do you see?",
          "Count each one, then choose.",
          "fruit_pack",
          ["items":"🍓 🍓 🍓", "count":"3"],
          ["2","3","4"], "3", .kindergarten),

        q(.math, "count_stars_5", "counting objects", "Emoji Counter Row", "Counting Objects",
          "How many stars do you see?",
          "Count each star.",
          "fun_pack",
          ["items":"⭐ ⭐ ⭐ ⭐ ⭐", "count":"5"],
          ["4","5","6"], "5", .kindergarten),

        q(.math, "more_apples_vs_pears", "more or less", "Comparison Card Pair", "Which Has More or Less",
          "Which group has MORE fruit?",
          "Tap the group with more.",
          "fruit_pack",
          ["left":"🍎 🍎 🍎 🍎 🍎", "right":"🍐 🍐", "leftLabel":"apples", "rightLabel":"pears"],
          ["apples","pears"], "apples", .kindergarten),

        q(.math, "add_1_plus_2", "addition by counting", "Emoji Counter Row", "Addition by Counting",
          "1 + 2 = ?",
          "Count both groups together.",
          "fruit_pack",
          ["left":"🍌", "right":"🍌 🍌", "equation":"1 + 2 = __"],
          ["2","3","4"], "3", .kindergarten),

        q(.math, "sub_4_minus_1", "subtraction by taking away", "Emoji Counter Row", "Subtraction by Taking Away",
          "4 cookies, take away 1. How many are left?",
          "Count the cookies that are not faded.",
          "food_pack",
          ["items":"🍪 🍪 🍪 ◌", "equation":"4 - 1 = __"],
          ["2","3","4"], "3", .kindergarten),

        q(.math, "pattern_ab_star_circle", "pattern recognition", "Pattern Row", "Pattern Recognition",
          "What comes next? ⭐ 🔵 ⭐ 🔵 __",
          "Choose the missing piece.",
          "shape_pack",
          ["sequence":"⭐, 🔵, ⭐, 🔵, blank"],
          ["⭐","🔵","🔴"], "⭐", .kindergarten),

        // ----- Expanded Grade 1 -----
        q(.math, "number_line_3_plus5", "number line jumps", "Number Line", "Number Line Jump",
          "Start at 3. Jump forward 5. Where do you land?",
          "Tap the landing number.",
          "symbol_support_pack",
          ["start":"3", "jump":"+5", "range":"0-12"],
          ["7","8","9"], "8", .grade1),

        q(.math, "make_ten_6", "make ten", "Ten-Frame", "Make Ten",
          "There are 6 dots. How many more make 10?",
          "Look at the empty spaces.",
          "symbol_support_pack",
          ["filled":"6", "empty":"4"],
          ["3","4","5"], "4", .grade1),

        q(.math, "missing_eq_2_plus_blank_10", "missing number equations", "Blank Slot Builder", "Missing Number Equation",
          "2 + __ = 10",
          "Drag the missing number into the blank.",
          "symbol_support_pack",
          ["equation":"2 + __ = 10", "chips":"6,7,8"],
          ["6","7","8"], "8", .grade1),

        q(.math, "true_false_3plus3_6", "true or false", "Choice Card Row", "True or False Math Statement",
          "Is 3 + 3 = 6 true or false?",
          "Choose true or false.",
          "symbol_support_pack",
          ["statement":"3 + 3 = 6"],
          ["True","False"], "True", .grade1),

        q(.math, "add_5_plus_4", "addition by counting", "Emoji Counter Row", "Addition by Counting",
          "5 + 4 = ?",
          "Add the two numbers.",
          "animal_pack",
          ["left":"🐶 🐶 🐶 🐶 🐶", "right":"🐱 🐱 🐱 🐱", "equation":"5 + 4 = __"],
          ["8","9","10"], "9", .grade1),

        q(.math, "compare_15_vs_9", "compare numbers", "Comparison Card Pair", "Compare Numbers",
          "Which number is bigger: 15 or 9?",
          "Tap the larger number.",
          "symbol_support_pack",
          ["left":"15", "right":"9"],
          ["15","9"], "15", .grade1),

        // ----- Expanded Grade 2 -----
        q(.math, "skip_count_10s", "skip counting", "Pattern Row", "Skip Counting Sequence",
          "What comes next: 10, 20, 30, 40, __?",
          "Count by 10s.",
          "symbol_support_pack",
          ["sequence":"10, 20, 30, 40, __"],
          ["45","50","55"], "50", .grade2),

        q(.math, "compare_67_vs_76", "compare numbers", "Comparison Card Pair", "Compare Numbers",
          "Which number is bigger: 67 or 76?",
          "Tap the larger number.",
          "symbol_support_pack",
          ["left":"67", "right":"76"],
          ["67","76"], "76", .grade2),

        q(.math, "time_2_30", "telling time", "Clock Card", "Telling Time",
          "What time does the clock show?",
          "Look at the hour and minute hands.",
          "symbol_support_pack",
          ["hour":"2", "minute":"30", "clock":"analog"],
          ["2:00","2:30","3:30"], "2:30", .grade2),

        q(.math, "missing_addend_blank_plus6_14", "missing number equations", "Blank Slot Builder", "Missing Number Equation",
          "__ + 6 = 14",
          "Drag the missing number into the blank.",
          "symbol_support_pack",
          ["equation":"__ + 6 = 14", "chips":"6,7,8"],
          ["6","7","8"], "8", .grade2),

        q(.math, "pattern_grow_plus4", "pattern recognition", "Pattern Row", "Pattern Recognition",
          "What comes next: 4, 8, 12, 16, __?",
          "Find the rule, then choose.",
          "symbol_support_pack",
          ["sequence":"4, 8, 12, 16, __"],
          ["18","20","22"], "20", .grade2),

        // ----- Expanded Grade 3 -----
        q(.math, "array_4x5", "multiplication arrays", "Array Builder", "Multiplication Arrays",
          "4 rows of 5 stars. How many stars are there?",
          "Count the array or use 4 × 5.",
          "shape_pack",
          ["rows":"4", "columns":"5", "item":"⭐"],
          ["18","20","24"], "20", .grade3),

        q(.math, "array_5x6", "multiplication arrays", "Array Builder", "Multiplication Arrays",
          "5 rows of 6 circles. How many circles are there?",
          "Count the array or use 5 × 6.",
          "shape_pack",
          ["rows":"5", "columns":"6", "item":"🔵"],
          ["28","30","32"], "30", .grade3),

        q(.math, "division_15_div_3", "division as sharing", "Grouping Buckets", "Division as Sharing",
          "Share 15 apples equally into 3 baskets. How many in each?",
          "Put the same number in every basket.",
          "fruit_pack",
          ["objects":"🍎x15", "buckets":"3"],
          ["4","5","6"], "5", .grade3),

        q(.math, "division_8_div_4", "division as sharing", "Grouping Buckets", "Division as Sharing",
          "Share 8 fish equally into 4 bowls. How many in each?",
          "Put the same number in every bowl.",
          "animal_pack",
          ["objects":"🐟x8", "buckets":"4"],
          ["2","3","4"], "2", .grade3),

        q(.math, "fraction_half_bar", "fractions basics", "Fraction or Fill Bar", "Fractions",
          "What fraction of the bar is shaded?",
          "Choose the matching fraction.",
          "symbol_support_pack",
          ["parts":"2", "filled":"1"],
          ["1/2","1/3","1/4"], "1/2", .grade3),

        q(.math, "fraction_sixths_bar", "fractions basics", "Fraction or Fill Bar", "Fractions",
          "What fraction of the bar is shaded?",
          "Choose the matching fraction.",
          "symbol_support_pack",
          ["parts":"6", "filled":"5"],
          ["5/6","1/3","1/4"], "5/6", .grade3),

        q(.math, "time_4_15", "telling time", "Clock Card", "Telling Time",
          "What time does the clock show?",
          "Look at both hands carefully.",
          "symbol_support_pack",
          ["hour":"4", "minute":"15", "clock":"analog"],
          ["4:15","5:15","4:45"], "4:15", .grade3),

        q(.math, "missing_factor_blank_x4_20", "missing number equations", "Blank Slot Builder", "Missing Number Equation",
          "__ × 4 = 20",
          "Drag the missing number.",
          "symbol_support_pack",
          ["equation":"__ × 4 = 20", "chips":"3,4,5"],
          ["3","4","5"], "5", .grade3),

        // ----- Timed Bonus (Speed Round) — countdown ring, 2 per grade band -----
        q(.math, "timed_k_2plus3", "timed bonus", "Choice Card Row", "Timed Bonus",
          "Quick! 2 + 3 = ?", "Answer before the timer runs out for a bonus!",
          "symbol_support_pack", ["equation":"2 + 3"], ["4","5","6"], "5", .kindergarten),
        q(.math, "timed_k_4plus1", "timed bonus", "Choice Card Row", "Timed Bonus",
          "Quick! 4 + 1 = ?", "Answer before the timer runs out for a bonus!",
          "symbol_support_pack", ["equation":"4 + 1"], ["4","5","6"], "5", .kindergarten),
        q(.math, "timed_g1_6plus4", "timed bonus", "Choice Card Row", "Timed Bonus",
          "Quick! 6 + 4 = ?", "Answer before the timer runs out for a bonus!",
          "symbol_support_pack", ["equation":"6 + 4"], ["9","10","11"], "10", .grade1),
        q(.math, "timed_g1_9minus3", "timed bonus", "Choice Card Row", "Timed Bonus",
          "Quick! 9 − 3 = ?", "Answer before the timer runs out for a bonus!",
          "symbol_support_pack", ["equation":"9 − 3"], ["5","6","7"], "6", .grade1),
        q(.math, "timed_g2_14plus5", "timed bonus", "Choice Card Row", "Timed Bonus",
          "Quick! 14 + 5 = ?", "Answer before the timer runs out for a bonus!",
          "symbol_support_pack", ["equation":"14 + 5"], ["18","19","20"], "19", .grade2),
        q(.math, "timed_g2_20minus6", "timed bonus", "Choice Card Row", "Timed Bonus",
          "Quick! 20 − 6 = ?", "Answer before the timer runs out for a bonus!",
          "symbol_support_pack", ["equation":"20 − 6"], ["13","14","15"], "14", .grade2),
        q(.math, "timed_g3_8x3", "timed bonus", "Choice Card Row", "Timed Bonus",
          "Quick! 8 × 3 = ?", "Answer before the timer runs out for a bonus!",
          "symbol_support_pack", ["equation":"8 × 3"], ["21","24","27"], "24", .grade3),
        q(.math, "timed_g3_7x4", "timed bonus", "Choice Card Row", "Timed Bonus",
          "Quick! 7 × 4 = ?", "Answer before the timer runs out for a bonus!",
          "symbol_support_pack", ["equation":"7 × 4"], ["24","28","32"], "28", .grade3)
    ]

    // =========================================================
    // MARK: - ENGLISH QUESTIONS
    // =========================================================
    // 0  Kindergarten — Letter Recognition (M vs N vs W — similar shapes)
    // 1  Kindergarten — Uppercase–Lowercase (B → b, close distractors d/p)
    // 2  Kindergarten — Beginning Sounds (/b/ with emoji)
    // 3  Kindergarten — Missing Letter (c_t → cat)
    // 4  Grade 2 — Correct Spelling (school)
    // 5  Grade 2 — Fill Missing Letters (b__k → book)
    // 6  Grade 1 — Unscramble (t a c → cat)
    // 7  Grade 1 — Rhyming (cat rhymes with hat)
    // 8  Kindergarten — Vocabulary Matching (apple emoji)
    // 9  Grade 1 — Word Families (-at family)
    // 10 Grade 1 — Sentence Building (The dog runs)
    // 11 Kindergarten — Sight Word (the)
    // 12 Grade 2 — Grammar Sorting (jump → verb)
    // 13 Grade 1 — Punctuation Choice (question mark)
    // 14 Grade 2 — Reading Comprehension (story + emoji)
    // 15 Kindergarten — Sequencing (morning routine)
    // 16 Kindergarten — Category Match (apple → Food)
    // 17 Grade 1 — Beginning Sound (/s/ snake)
    // 18 Grade 1 — Unscramble (d o g → dog)
    // 19 Grade 2 — Rhyming (-ight family)
    // 20 Grade 3 — Sentence Building (longer, with adjective)
    // 21 Grade 3 — Grammar Sorting (noun vs verb, two words)
    // 22 Grade 2 — Sight Word (because)
    // 23 Grade 3 — Reading Comprehension (longer passage)
    // 24 Grade 1 — Missing Letter (sh_p → ship)
    // 25 Grade 2 — Fill Missing Letters (tr__n → train)
    // 26 Grade 3 — Punctuation (exclamation)
    // 27 Kindergarten — Letter Recognition (S vs similar)
    // 28 Grade 1 — Word Families (-ig family)
    // 29 Grade 3 — Vocabulary (synonym: happy)
    static let sampleEnglishQuestions: [NormalizedQuestion] = [

        // 0 — Kindergarten: Letter Recognition (M, close distractors)
        q(.english, "letter_M", "letter recognition", "Letter Tile", "Letter Recognition",
          "Find the letter M",
          "Tap the letter M.",
          "letter_pack",
          ["target":"M"],
          ["M","N","W"], "M", .kindergarten),

        // 1 — Kindergarten: Uppercase–Lowercase (B → b)
        q(.english, "upper_lower_B", "uppercase-lowercase", "Matching Card Set", "Uppercase-Lowercase Matching",
          "Match B to its lowercase letter.",
          "Tap the lowercase b.",
          "letter_pack",
          ["uppercase":"B"],
          ["b","d","p"], "b", .kindergarten),

        // 2 — Kindergarten: Beginning Sounds (/b/ → bear)
        q(.english, "begin_sound_b", "beginning sounds", "Choice Card Row", "Beginning Sounds",
          "Which picture starts with the letter B?",
          "Tap the picture that starts with B.",
          "animal_vocab_pack",
          ["sound":"b"],
          ["🐻","🐸","🐢"], "🐻", .kindergarten),

        // 3 — Kindergarten: Missing Letter (c_t → cat, emoji hint 🐱)
        q(.english, "missing_letter_cat", "missing letter", "Blank Slot Builder", "Missing Letter",
          "c _ t",
          "Choose the missing letter to make cat.",
          "cvc_pack",
          ["wordWithBlank":"c_t", "emoji":"🐱"],
          ["a","o","i"], "a", .kindergarten),

        // 4 — Grade 2: Correct Spelling (school vs skool vs scool)
        q(.english, "spelling_school", "spelling", "Choice Card Row", "Choose Correct Spelling",
          "Which word is spelled correctly?",
          "Tap the correct spelling.",
          "common_school_words_pack",
          ["meaning":"place where you learn"],
          ["skool","school","scool"], "school", .grade2),

        // 5 — Grade 2: Fill Missing Letters (b__k → book, emoji 📚)
        q(.english, "fill_letters_book", "fill missing letters", "Blank Slot Builder", "Fill Missing Letters",
          "b _ _ k",
          "Fill the missing letters to make book.",
          "common_school_words_pack",
          ["wordWithBlanks":"b__k", "emoji":"📚"],
          ["oo","oa","ee"], "oo", .grade2),

        // 6 — Grade 1: Unscramble (t a c → cat, emoji 🐱)
        q(.english, "unscramble_cat", "unscramble", "Word Builder Tray", "Unscramble Word",
          "Unscramble these letters: a  t  c",
          "Build the animal word.",
          "cvc_pack",
          ["letters":"a,t,c", "hint":"🐱"],
          ["cat"], "cat", .grade1),

        // 7 — Grade 1: Rhyming (cat → hat)
        q(.english, "rhyme_cat_hat", "rhyming", "Pattern Row", "Rhyming Words",
          "Which word rhymes with cat? 🐱",
          "Choose the rhyming word.",
          "word_family_pack",
          ["target":"cat"],
          ["hat","dog","sun"], "hat", .grade1),

        // 8 — Kindergarten: Vocabulary Matching (apple → 🍎)
        q(.english, "vocab_apple", "vocabulary", "Matching Card Set", "Vocabulary Matching",
          "Match apple to its picture.",
          "Choose the apple emoji.",
          "food_vocab_pack",
          ["word":"apple"],
          ["🍎","🍕","🥕"], "🍎", .kindergarten),

        // 9 — Grade 1: Word Families (-at family: bat)
        q(.english, "word_family_at", "word families", "Pattern Row", "Word Families",
          "Which word belongs with cat and hat?",
          "Find the -at word.",
          "word_family_pack",
          ["family":"-at"],
          ["bat","bed","cup"], "bat", .grade1),

        // 10 — Grade 1: Sentence Building (The dog runs)
        q(.english, "sentence_the_dog_runs", "sentence building", "Sentence Strip", "Sentence Building",
          "Put the words in order to make a sentence.",
          "Tap the words in the right order.",
          "simple_nouns_pack",
          ["tokens":"runs,The,dog"],
          ["The dog runs"], "The dog runs", .grade1),

        // 11 — Kindergarten: Sight Word (the)
        q(.english, "sight_the", "sight words", "Choice Card Row", "Sight Word Recognition",
          "Which word is \"the\"?",
          "Tap the word that matches.",
          "sight_words_pack",
          ["target":"the"],
          ["the","then","them"], "the", .kindergarten),

        // 12 — Grade 2: Grammar Sorting (jump → Verb)
        q(.english, "grammar_jump_verb", "grammar sorting", "Grouping Buckets", "Grammar Sorting",
          "Is jump a noun or a verb?",
          "Put the word in the right bucket.",
          "simple_verbs_pack",
          ["word":"jump"],
          ["Noun","Verb"], "Verb", .grade2),

        // 13 — Grade 1: Punctuation Choice (question mark for where are you)
        q(.english, "punct_question", "punctuation", "Sentence Strip", "Punctuation Choice",
          "Where are you __",
          "Choose the correct punctuation mark.",
          "symbol_support_pack",
          ["sentence":"Where are you"],
          [".","?","!"], "?", .grade1),

        // 14 — Grade 2: Reading Comprehension (James went to school)
        q(.english, "story_james_school", "reading comprehension", "Story Emoji Strip", "Reading Comprehension",
          "🛏️ 🪥 🚌  James got ready and rode the bus. Where did James go?",
          "Use the emojis and the sentence to choose.",
          "daily_routine_pack",
          ["emojis":"🛏️,🪥,🚌", "text":"James got ready and rode the bus to school."],
          ["school","park","store"], "school", .grade2),

        // 15 — Kindergarten: Sequencing (morning routine, 3 steps)
        q(.english, "sequence_morning", "sequencing", "Sequence Card Row", "Sequencing",
          "Put the morning steps in the right order.",
          "Drag first, next, then last.",
          "daily_routine_pack",
          ["cards":"wake up,brush teeth,ride bus"],
          ["wake up > brush teeth > ride bus"], "wake up > brush teeth > ride bus", .kindergarten),

        // 16 — Kindergarten: Category Match (apple → Food)
        q(.english, "category_apple_food", "category match", "Grouping Buckets", "Category Match",
          "Does apple belong in Food or Place?",
          "Choose the right bucket.",
          "food_vocab_pack",
          ["item":"apple"],
          ["Food","Place"], "Food", .kindergarten),

        // 17 — Grade 1: Beginning Sound (/s/ → snake)
        q(.english, "begin_sound_s", "beginning sounds", "Choice Card Row", "Beginning Sounds",
          "Which picture starts with the letter S?",
          "Tap the picture that starts with S.",
          "animal_vocab_pack",
          ["sound":"s"],
          ["🐍","🐻","🐸"], "🐍", .grade1),

        // 18 — Grade 1: Unscramble (d o g → dog, emoji 🐶)
        q(.english, "unscramble_dog", "unscramble", "Word Builder Tray", "Unscramble Word",
          "Unscramble these letters: o  g  d",
          "Build the animal word.",
          "animal_vocab_pack",
          ["letters":"o,g,d", "hint":"🐶"],
          ["dog"], "dog", .grade1),

        // 19 — Grade 2: Rhyming (-ight family: night → light)
        q(.english, "rhyme_night_light", "rhyming", "Pattern Row", "Rhyming Words",
          "Which word rhymes with night? 🌙",
          "Choose the rhyming word.",
          "word_family_pack",
          ["target":"night"],
          ["light","moon","dark"], "light", .grade2),

        // 20 — Grade 3: Sentence Building (longer, with adjective)
        q(.english, "sentence_big_dog_ran", "sentence building", "Sentence Strip", "Sentence Building",
          "Put the words in order to make a sentence.",
          "Tap the words in the right order.",
          "simple_nouns_pack",
          ["tokens":"quickly,The,big,ran,dog"],
          ["The big dog ran quickly"], "The big dog ran quickly", .grade3),

        // 21 — Grade 3: Grammar Sorting (two words: happiness → Noun, swim → Verb)
        q(.english, "grammar_happiness_noun", "grammar sorting", "Grouping Buckets", "Grammar Sorting",
          "Is happiness a noun or a verb?",
          "Put it in the right bucket.",
          "simple_nouns_pack",
          ["word":"happiness"],
          ["Noun","Verb"], "Noun", .grade3),

        // 22 — Grade 2: Sight Word (because)
        // NOTE: word choices render as chips in FlowRow (minWidth 96). Keep word
        // choices under ~8 characters to avoid wrapping across two lines.
        q(.english, "sight_because", "sight words", "Choice Card Row", "Sight Word Recognition",
          "Which word is \"because\"?",
          "Tap the word that matches.",
          "sight_words_pack",
          ["target":"because"],
          ["because","before","became"], "because", .grade2),

        // 23 — Grade 3: Reading Comprehension (two-sentence passage)
        q(.english, "story_mia_library", "reading comprehension", "Story Emoji Strip", "Reading Comprehension",
          "📚 🚶 😊  Mia walked to the library. She chose three books about animals. What did Mia borrow?",
          "Read the sentence and choose the right answer.",
          "places_pack",
          ["emojis":"📚,🚶,😊", "text":"Mia walked to the library and chose three books about animals."],
          ["books","toys","clothes"], "books", .grade3),

        // 24 — Grade 1: Missing Letter (sh_p → ship, emoji 🚢)
        q(.english, "missing_letter_ship", "missing letter", "Blank Slot Builder", "Missing Letter",
          "sh _ p",
          "Choose the missing letter to make ship.",
          "cvc_pack",
          ["wordWithBlank":"sh_p", "emoji":"🚢"],
          ["i","a","u"], "i", .grade1),

        // 25 — Grade 2: Fill Missing Letters (tr__n → train, emoji 🚂)
        q(.english, "fill_letters_train", "fill missing letters", "Blank Slot Builder", "Fill Missing Letters",
          "tr _ _ n",
          "Fill the missing letters to make train.",
          "common_school_words_pack",
          ["wordWithBlanks":"tr__n", "emoji":"🚂"],
          ["ai","ea","oa"], "ai", .grade2),

        // 26 — Grade 3: Punctuation Choice (exclamation for excitement)
        q(.english, "punct_exclaim", "punctuation", "Sentence Strip", "Punctuation Choice",
          "We won the game __",
          "Choose the correct punctuation mark.",
          "symbol_support_pack",
          ["sentence":"We won the game"],
          [".","?","!"], "!", .grade3),

        // 27 — Kindergarten: Letter Recognition (S vs similar)
        q(.english, "letter_S", "letter recognition", "Letter Tile", "Letter Recognition",
          "Find the letter S",
          "Tap the letter S.",
          "letter_pack",
          ["target":"S"],
          ["S","C","G"], "S", .kindergarten),

        // 28 — Grade 1: Word Families (-ig family: pig)
        q(.english, "word_family_ig", "word families", "Pattern Row", "Word Families",
          "Which word belongs with big and wig?",
          "Find the -ig word.",
          "word_family_pack",
          ["family":"-ig"],
          ["pig","pan","bug"], "pig", .grade1),

        // 29 — Grade 3: Vocabulary — synonym for happy
        q(.english, "vocab_synonym_happy", "vocabulary", "Choice Card Row", "Vocabulary Matching",
          "Which word means the same as happy? 😊",
          "Choose the best synonym.",
          "emotion_pack",
          ["word":"happy"],
          ["joyful","angry","tired"], "joyful", .grade3),

        // 30 — Grade 2: Unscramble (scrambled letters → monkey, emoji 🐒)
        q(.english, "unscramble_monkey", "unscramble", "Word Builder Tray", "Unscramble Word",
          "Unscramble these letters: y  n  k  o  e  m",
          "Build the animal word.",
          "animal_vocab_pack",
          ["letters":"y,n,k,o,e,m", "hint":"🐒"],
          ["monkey"], "monkey", .grade2),

        // ----- Expanded Kindergarten -----
        q(.english, "letter_A", "letter recognition", "Letter Tile", "Letter Recognition",
          "Find the letter A",
          "Tap the letter A.",
          "letter_pack",
          ["target":"A"],
          ["A","E","H"], "A", .kindergarten),

        q(.english, "upper_lower_D", "uppercase-lowercase", "Matching Card Set", "Uppercase-Lowercase Matching",
          "Match D to its lowercase letter.",
          "Tap the lowercase d.",
          "letter_pack",
          ["uppercase":"D"],
          ["d","b","p"], "d", .kindergarten),

        q(.english, "begin_sound_d_dog", "beginning sounds", "Choice Card Row", "Beginning Sounds",
          "Which picture starts with the letter D?",
          "Tap the picture that starts with D.",
          "animal_vocab_pack",
          ["sound":"d"],
          ["🐶","🐱","🐻"], "🐶", .kindergarten),

        q(.english, "missing_letter_dog", "missing letter", "Blank Slot Builder", "Missing Letter",
          "d _ g",
          "Choose the missing letter to make dog.",
          "cvc_pack",
          ["wordWithBlank":"d_g", "emoji":"🐶"],
          ["o","a","i"], "o", .kindergarten),

        q(.english, "sight_and", "sight words", "Choice Card Row", "Sight Word Recognition",
          "Which word is \"and\"?",
          "Tap the word that matches.",
          "sight_words_pack",
          ["target":"and"],
          ["and","can","had"], "and", .kindergarten),

        q(.english, "vocab_dog_picture", "vocabulary", "Matching Card Set", "Vocabulary Matching",
          "Match dog to its picture.",
          "Choose the dog emoji.",
          "animal_vocab_pack",
          ["word":"dog"],
          ["🐶","🐱","🐰"], "🐶", .kindergarten),

        // ----- Expanded Grade 1 -----
        q(.english, "unscramble_sun", "unscramble", "Word Builder Tray", "Unscramble Word",
          "Unscramble these letters: u  n  s",
          "Build the word.",
          "cvc_pack",
          ["letters":"u,n,s", "hint":"☀️"],
          ["sun"], "sun", .grade1),

        q(.english, "rhyme_dog_log", "rhyming", "Pattern Row", "Rhyming Words",
          "Which word rhymes with dog? 🐶",
          "Choose the rhyming word.",
          "word_family_pack",
          ["target":"dog"],
          ["log","sun","cat"], "log", .grade1),

        q(.english, "word_family_op", "word families", "Pattern Row", "Word Families",
          "Which word belongs with top and hop?",
          "Find the -op word.",
          "word_family_pack",
          ["family":"-op"],
          ["mop","bug","pen"], "mop", .grade1),

        q(.english, "sentence_i_see_you", "sentence building", "Sentence Strip", "Sentence Building",
          "Put the words in order to make a sentence.",
          "Tap the words in the right order.",
          "simple_nouns_pack",
          ["tokens":"you,I,see"],
          ["I see you"], "I see you", .grade1),

        q(.english, "punct_statement", "punctuation", "Sentence Strip", "Punctuation Choice",
          "The sky is blue __",
          "Choose the correct punctuation mark.",
          "symbol_support_pack",
          ["sentence":"The sky is blue"],
          [".","?","!"], ".", .grade1),

        q(.english, "begin_sound_f_frog", "beginning sounds", "Choice Card Row", "Beginning Sounds",
          "Which picture starts with the letter F?",
          "Tap the picture that starts with F.",
          "animal_vocab_pack",
          ["sound":"f"],
          ["🐸","🐻","🐍"], "🐸", .grade1),

        // ----- Expanded Grade 2 -----
        q(.english, "spelling_friend", "spelling", "Choice Card Row", "Choose Correct Spelling",
          "Which word is spelled correctly?",
          "Tap the correct spelling.",
          "common_school_words_pack",
          ["meaning":"someone you like"],
          ["freind","friend","frend"], "friend", .grade2),

        q(.english, "fill_letters_rain", "fill missing letters", "Blank Slot Builder", "Fill Missing Letters",
          "r _ _ n",
          "Fill the missing letters to make rain.",
          "common_school_words_pack",
          ["wordWithBlanks":"r__n", "emoji":"🌧️"],
          ["ai","ea","oa"], "ai", .grade2),

        q(.english, "grammar_run_verb", "grammar sorting", "Grouping Buckets", "Grammar Sorting",
          "Is run a noun or a verb?",
          "Put the word in the right bucket.",
          "simple_verbs_pack",
          ["word":"run"],
          ["Noun","Verb"], "Verb", .grade2),

        q(.english, "rhyme_cake_lake", "rhyming", "Pattern Row", "Rhyming Words",
          "Which word rhymes with cake? 🎂",
          "Choose the rhyming word.",
          "word_family_pack",
          ["target":"cake"],
          ["lake","fish","book"], "lake", .grade2),

        q(.english, "sight_their", "sight words", "Choice Card Row", "Sight Word Recognition",
          "Which word is \"their\"?",
          "Tap the word that matches.",
          "sight_words_pack",
          ["target":"their"],
          ["their","there","three"], "their", .grade2),

        // ----- Expanded Grade 3 -----
        q(.english, "sentence_quick_fox", "sentence building", "Sentence Strip", "Sentence Building",
          "Put the words in order to make a sentence.",
          "Tap the words in the right order.",
          "simple_nouns_pack",
          ["tokens":"ran,The,fox,quick,fast"],
          ["The quick fox ran fast"], "The quick fox ran fast", .grade3),

        q(.english, "vocab_synonym_big", "vocabulary", "Choice Card Row", "Vocabulary Matching",
          "Which word means the same as big?",
          "Choose the best synonym.",
          "emotion_pack",
          ["word":"big"],
          ["huge","small","tiny"], "huge", .grade3),

        q(.english, "vocab_synonym_fast", "vocabulary", "Choice Card Row", "Vocabulary Matching",
          "Which word means the same as fast?",
          "Choose the best synonym.",
          "emotion_pack",
          ["word":"fast"],
          ["quick","slow","still"], "quick", .grade3),

        q(.english, "grammar_freedom_noun", "grammar sorting", "Grouping Buckets", "Grammar Sorting",
          "Is freedom a noun or a verb?",
          "Put it in the right bucket.",
          "simple_nouns_pack",
          ["word":"freedom"],
          ["Noun","Verb"], "Noun", .grade3),

        q(.english, "punct_question_3", "punctuation", "Sentence Strip", "Punctuation Choice",
          "Are you coming with us __",
          "Choose the correct punctuation mark.",
          "symbol_support_pack",
          ["sentence":"Are you coming with us"],
          [".","?","!"], "?", .grade3),

        // ----- Memory Match — flip cards, 2 per grade band -----
        q(.english, "memory_k_abc", "memory match", "Memory Cards", "Memory Match",
          "Match each capital letter to its lowercase.", "Tap two cards to find a pair.",
          "letter_pack", ["pairs":"A|a,B|b,C|c"], ["matched"], "matched", .kindergarten),
        q(.english, "memory_k_def", "memory match", "Memory Cards", "Memory Match",
          "Match each capital letter to its lowercase.", "Tap two cards to find a pair.",
          "letter_pack", ["pairs":"D|d,E|e,F|f"], ["matched"], "matched", .kindergarten),
        q(.english, "memory_g1_words", "memory match", "Memory Cards", "Memory Match",
          "Find the matching pairs.", "Tap two cards to find a pair.",
          "animal_vocab_pack", ["pairs":"🐱|cat,🐶|dog,☀️|sun"], ["matched"], "matched", .grade1),
        q(.english, "memory_g1_words2", "memory match", "Memory Cards", "Memory Match",
          "Find the matching pairs.", "Tap two cards to find a pair.",
          "animal_vocab_pack", ["pairs":"🍎|apple,🚗|car,⭐|star"], ["matched"], "matched", .grade1),
        q(.english, "memory_g2_words", "memory match", "Memory Cards", "Memory Match",
          "Find the matching pairs.", "Tap two cards to find a pair.",
          "food_vocab_pack", ["pairs":"🍌|banana,📚|book,🌸|flower,🐢|turtle"], ["matched"], "matched", .grade2),
        q(.english, "memory_g2_words2", "memory match", "Memory Cards", "Memory Match",
          "Find the matching pairs.", "Tap two cards to find a pair.",
          "food_vocab_pack", ["pairs":"🍕|pizza,🥕|carrot,🐰|rabbit,🌳|tree"], ["matched"], "matched", .grade2),
        q(.english, "memory_g3_words", "memory match", "Memory Cards", "Memory Match",
          "Find the matching pairs.", "Tap two cards to find a pair.",
          "places_pack", ["pairs":"🌸|flower,🐉|dragon,🚀|rocket,🐒|monkey"], ["matched"], "matched", .grade3),
        q(.english, "memory_g3_words2", "memory match", "Memory Cards", "Memory Match",
          "Find the matching pairs.", "Tap two cards to find a pair.",
          "places_pack", ["pairs":"🏫|school,🌙|moon,⏰|clock,🐍|snake"], ["matched"], "matched", .grade3),

        // ----- Category Sort — multi-item drag-to-sort, 2 per grade band -----
        q(.english, "sort_k_animals_food", "word sort", "Sort Buckets", "Category Sort",
          "Sort each into Animals or Food.", "Tap an item, then tap its bucket.",
          "word_packs", ["buckets":"Animals,Food", "items":"🐶 dog|Animals,🐱 cat|Animals,🍎 apple|Food,🍕 pizza|Food"], ["sorted"], "sorted", .kindergarten),
        q(.english, "sort_k_animals_things", "word sort", "Sort Buckets", "Category Sort",
          "Sort each into Animals or Things.", "Tap an item, then tap its bucket.",
          "word_packs", ["buckets":"Animals,Things", "items":"🐸 frog|Animals,🐢 turtle|Animals,🚗 car|Things,📚 book|Things"], ["sorted"], "sorted", .kindergarten),
        q(.english, "sort_g1_animals_food", "word sort", "Sort Buckets", "Category Sort",
          "Sort each into Animals or Food.", "Tap an item, then tap its bucket.",
          "word_packs", ["buckets":"Animals,Food", "items":"🐰 rabbit|Animals,🐍 snake|Animals,🍪 cookie|Food,🍌 banana|Food"], ["sorted"], "sorted", .grade1),
        q(.english, "sort_g1_food_plants", "word sort", "Sort Buckets", "Category Sort",
          "Sort each into Food or Plants.", "Tap an item, then tap its bucket.",
          "word_packs", ["buckets":"Food,Plants", "items":"🥕 carrot|Food,🌽 corn|Food,🌸 flower|Plants,🌳 tree|Plants"], ["sorted"], "sorted", .grade1),
        q(.english, "sort_g2_nouns_verbs", "word sort", "Sort Buckets", "Category Sort",
          "Sort each into Nouns or Verbs.", "Tap an item, then tap its bucket.",
          "word_packs", ["buckets":"Nouns,Verbs", "items":"dog|Nouns,book|Nouns,run|Verbs,jump|Verbs"], ["sorted"], "sorted", .grade2),
        q(.english, "sort_g2_nouns_verbs2", "word sort", "Sort Buckets", "Category Sort",
          "Sort each into Nouns or Verbs.", "Tap an item, then tap its bucket.",
          "word_packs", ["buckets":"Nouns,Verbs", "items":"school|Nouns,apple|Nouns,read|Verbs,swim|Verbs"], ["sorted"], "sorted", .grade2),
        q(.english, "sort_g3_nouns_verbs", "word sort", "Sort Buckets", "Category Sort",
          "Sort each into Nouns or Verbs.", "Tap an item, then tap its bucket.",
          "word_packs", ["buckets":"Nouns,Verbs", "items":"freedom|Nouns,garden|Nouns,sing|Verbs,dance|Verbs"], ["sorted"], "sorted", .grade3),
        q(.english, "sort_g3_nouns_verbs2", "word sort", "Sort Buckets", "Category Sort",
          "Sort each into Nouns or Verbs.", "Tap an item, then tap its bucket.",
          "word_packs", ["buckets":"Nouns,Verbs", "items":"happiness|Nouns,house|Nouns,eat|Verbs,sleep|Verbs"], ["sorted"], "sorted", .grade3)
    ]

    // MARK: - Private builders (unchanged)
    private static func c(_ name: String, _ purpose: String, _ visual: String, _ skills: [String], _ interactions: [String], _ scaling: String, _ fields: [String]) -> CurriculumComponent {
        CurriculumComponent(name: name, purpose: purpose, visualDescription: visual, supportedSkills: skills, supportedInteractions: interactions, difficultyScaling: scaling, requiredDataFields: fields)
    }

    private static func mt(_ name: String, _ component: String, _ goal: String, _ grades: [GradeBand], _ pattern: String, _ packs: [String], _ interaction: String, _ sample: NormalizedQuestion) -> CurriculumTemplate {
        CurriculumTemplate(templateName: name, associatedComponent: component, learningGoal: goal, supportedGradeBands: grades, promptPattern: pattern, supportedVisualPacks: packs, interactionType: interaction, hintBehavior: mathHintRules[sample.skill] ?? "Highlight the relevant visual clue.", difficultyNotes: "Easy narrows choices; Balanced follows grade default; Adaptive adjusts range and distractors based on recent accuracy.", sampleQuestion: sample)
    }

    private static func et(_ name: String, _ component: String, _ goal: String, _ grades: [GradeBand], _ pattern: String, _ packs: [String], _ interaction: String, _ sample: NormalizedQuestion) -> CurriculumTemplate {
        CurriculumTemplate(templateName: name, associatedComponent: component, learningGoal: goal, supportedGradeBands: grades, promptPattern: pattern, supportedVisualPacks: packs, interactionType: interaction, hintBehavior: englishHintRules[sample.skill] ?? "Highlight the relevant text or visual clue.", difficultyNotes: "Easy uses obvious contrasts; Balanced follows grade default; Adaptive changes distractors, word length, and hint timing.", sampleQuestion: sample)
    }

    private static func q(_ subject: CurriculumSubject, _ id: String, _ skill: String, _ component: String, _ template: String, _ prompt: String, _ directions: String, _ source: String, _ content: [String: String], _ choices: [String], _ correct: String, _ grade: GradeBand) -> NormalizedQuestion {
        NormalizedQuestion(id: id, subject: subject, skill: skill, component: component, templateType: template, prompt: prompt, directions: directions, visualSource: source, questionContent: content, answerChoices: choices, correctAnswer: correct, interactionType: choices.count == 1 ? "drag_or_reorder" : "tap_choice", difficulty: .balanced, hintType: skill, feedbackCorrect: "Nice work — time earned!", feedbackIncorrect: "Almost. Use the visual hint and try again.", gradeBand: grade, estimatedSeconds: 20, masteryTag: skill.replacingOccurrences(of: " ", with: "_"), curriculumUnit: subject.rawValue, sessionGoal: "unlock_app_time", unlockContext: "3 questions = 15 minutes; 5 questions = 20 minutes", questionSeed: id)
    }
}