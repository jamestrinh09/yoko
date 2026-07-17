//
//  QuestionExplanations.swift
//  Yoko
//

import Foundation

enum QuestionExplanations {
    static let byTemplate: [String: String] = [
        // Math
        "Counting Objects": "Count out loud and tap each one. The last number you say is the answer.",
        "Which Has More or Less": "Draw invisible lines connecting them in pairs. Whoever has a leftover wins.",
        "Addition by Counting": "Start from the bigger number and count up.",
        "Subtraction by Taking Away": "Start at the bigger number and count backwards.",
        "Missing Number Equation": "Work backwards from the total to find the missing part.",
        "Number Line Jump": "Put your finger on the start number, then hop along the line.",
        "Make Ten": "Count how many more you'd need to reach ten on your fingers.",
        "Skip Counting Sequence": "Look at how much the numbers grow each step.",
        "Multiplication Arrays": "Count one row, then add that many for every row.",
        "Division as Sharing": "Give one to each group at a time until none are left.",
        "Pattern Recognition": "Say the pattern out loud like a song. Your ears will hear where it repeats.",
        "Fractions": "Count all the pieces — that's the bottom number. Count the shaded ones — that's the top.",
        "Telling Time": "Short hand points to the hour, long hand points to the minutes.",
        "Compare Numbers": "The number that would come later when counting up is the bigger one.",
        "True or False Math Statement": "Cover the answer, solve it yourself, then peek to see if they match.",
        "Timed Bonus": "Answer quickly, add or subtract like you've practiced.",
        // English
        "Letter Recognition": "Say the picture's name and listen for the first sound.",
        "Uppercase-Lowercase Matching": "Big and little letters are like grown-ups and their kids. Find the ones that look related.",
        "Beginning Sounds": "Say each picture's name. Which one starts with that sound?",
        "Missing Letter": "Say the word slowly and listen for the missing sound.",
        "Choose Correct Spelling": "Sound out each choice and picture the word.",
        "Fill Missing Letters": "Say the word slowly and listen for the missing part.",
        "Unscramble Word": "Look at the picture clue, then find which letter comes first.",
        "Rhyming Words": "Say the words out loud. Rhymes end with the same sound.",
        "Vocabulary Matching": "Use the word in a little sentence. That helps you feel what it means.",
        "Word Families": "Family words share the same ending letters.",
        "Sentence Building": "Read your sentence out loud. If it sounds like how people talk, it's right.",
        "Sight Word Recognition": "Read the whole sentence. Which word makes it fit?",
        "Punctuation Choice": "Is it asking, telling, or exciting? That picks the mark.",
        "Reading Comprehension": "The answer is hiding in the story. Go back and point to where it tells you.",
        "Sequencing": "Picture it like a movie in your head. What had to happen before the next part could?",
        "Memory Match": "When you flip a card, whisper where it is out loud so your brain remembers it.",
        "Category Sort": "Ask what each one is, not what it looks like. A red apple and a red ball go in different groups."
    ]

    /// Content-aware explanation lookup. Falls back to the static dictionary when
    /// no special branching applies.
    static func text(for templateType: String, buckets: [String] = [], choices: [String] = [], equation: String = "") -> String {
        switch templateType {
        // Category Sort — grammar vs physical
        case "Category Sort":
            let grammarBuckets: Set<String> = ["Nouns", "Verbs"]
            if !buckets.isEmpty && grammarBuckets.contains(buckets[0]) {
                return "If you can put 'a' or 'the' in front of it, it's a noun. If you can do it, it's a verb."
            }
            return "Ask what each one is, not what it looks like. A red apple and a red ball go in different groups."

        // Vocabulary Matching — emoji vs synonym
        case "Vocabulary Matching":
            let isEmojiChoices = !choices.isEmpty && choices.allSatisfy { choice in
                let trimmed = choice.trimmingCharacters(in: .whitespaces)
                return trimmed.unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.properties.isEmoji }
                    && trimmed.count <= 2
            }
            if isEmojiChoices {
                return "Say the word out loud. Which picture matches what you said?"
            }
            return "Use the word in a little sentence. That helps you feel what it means."

        // Pattern Recognition — numeric vs visual
        case "Pattern Recognition":
            let isNumeric = !choices.isEmpty && choices.allSatisfy { Int($0) != nil }
            if isNumeric {
                return "Look at how much the numbers grow each step."
            }
            return "Say the pattern out loud like a song. Your ears will hear where it repeats."

        // Missing Number Equation — multiplication vs add/subtract
        case "Missing Number Equation":
            if equation.contains("×") || equation.contains("*") {
                return "Think: what number times the other equals the answer?"
            }
            return "Work backwards from the total to find the missing part."

        // Fractions — updated wording
        case "Fractions":
            return "Count all the pieces — that's the bottom number. Count the shaded ones — that's the top."

        default:
            return byTemplate[templateType] ?? "Take your time and think through each step."
        }
    }
}
