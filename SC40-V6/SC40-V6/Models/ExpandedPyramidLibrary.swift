import Foundation

// MARK: - Expanded Pyramid Library
// Upward and Downward Pyramids for All Levels (Sessions 301-400)

let expandedPyramidLibrary: [SprintSessionTemplate] = [
    
    // MARK: - Upward Pyramids (301-350) - Build Up Only
    
    // Beginner Upward Pyramids (301-315)
    SprintSessionTemplate(id: 301, name: "Beginner Upward 5-10-15 yd", distance: 15, reps: 3, rest: 90, focus: "Progressive Acceleration", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 302, name: "Beginner Upward 10-15-20 yd", distance: 20, reps: 3, rest: 100, focus: "Speed Building", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 303, name: "Beginner Upward 5-15-25 yd", distance: 25, reps: 3, rest: 110, focus: "Distance Progression", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 304, name: "Beginner Upward 10-20-30 yd", distance: 30, reps: 3, rest: 120, focus: "Classic Build", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 305, name: "Beginner Upward 8-16-24 yd", distance: 24, reps: 3, rest: 105, focus: "Doubling Pattern", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 306, name: "Beginner Upward 12-18-24 yd", distance: 24, reps: 3, rest: 110, focus: "6-Yard Steps", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 307, name: "Beginner Upward 5-10-20 yd", distance: 20, reps: 3, rest: 100, focus: "Variable Steps", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 308, name: "Beginner Upward 10-25-40 yd", distance: 40, reps: 3, rest: 130, focus: "Large Jumps", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 309, name: "Beginner Upward 15-20-25 yd", distance: 25, reps: 3, rest: 105, focus: "Small Steps", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 310, name: "Beginner Upward 6-12-18-24 yd", distance: 24, reps: 4, rest: 100, focus: "4-Step Build", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 311, name: "Beginner Upward 5-10-15-20-25 yd", distance: 25, reps: 5, rest: 95, focus: "5-Step Progressive", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 312, name: "Beginner Upward 10-15-25-35 yd", distance: 35, reps: 4, rest: 115, focus: "Irregular Build", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 313, name: "Beginner Upward 8-20-32 yd", distance: 32, reps: 3, rest: 120, focus: "Exponential Growth", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 314, name: "Beginner Upward 7-14-21-28 yd", distance: 28, reps: 4, rest: 110, focus: "7-Yard Multiples", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 315, name: "Beginner Upward 5-20-35 yd", distance: 35, reps: 3, rest: 125, focus: "Progressive Leaps", level: "Beginner", sessionType: .sprint),
    
    // Intermediate Upward Pyramids (316-330)
    SprintSessionTemplate(id: 316, name: "Intermediate Upward 10-20-30-40 yd", distance: 40, reps: 4, rest: 140, focus: "Classic 4-Step", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 317, name: "Intermediate Upward 15-30-45 yd", distance: 45, reps: 3, rest: 160, focus: "15-Yard Steps", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 318, name: "Intermediate Upward 20-35-50 yd", distance: 50, reps: 3, rest: 170, focus: "Power Build", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 319, name: "Intermediate Upward 10-25-40-55 yd", distance: 55, reps: 4, rest: 165, focus: "Varied Increments", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 320, name: "Intermediate Upward 12-24-36-48 yd", distance: 48, reps: 4, rest: 145, focus: "12-Yard Pattern", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 321, name: "Intermediate Upward 20-30-40-50-60 yd", distance: 60, reps: 5, rest: 170, focus: "10-Yard Steps", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 322, name: "Intermediate Upward 15-25-35-45-55 yd", distance: 55, reps: 5, rest: 155, focus: "Steady Progression", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 323, name: "Intermediate Upward 25-50-75 yd", distance: 75, reps: 3, rest: 200, focus: "25-Yard Jumps", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 324, name: "Intermediate Upward 18-30-42-54 yd", distance: 54, reps: 4, rest: 160, focus: "12-Yard Variable", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 325, name: "Intermediate Upward 10-30-50 yd", distance: 50, reps: 3, rest: 170, focus: "20-Yard Jumps", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 326, name: "Intermediate Upward 16-28-40-52 yd", distance: 52, reps: 4, rest: 155, focus: "Variable Steps", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 327, name: "Intermediate Upward 20-40-60 yd", distance: 60, reps: 3, rest: 180, focus: "20-Yard Doubles", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 328, name: "Intermediate Upward 14-28-42-56-70 yd", distance: 70, reps: 5, rest: 175, focus: "14-Yard Multiples", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 329, name: "Intermediate Upward 22-33-44-55 yd", distance: 55, reps: 4, rest: 165, focus: "11-Yard Steps", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 330, name: "Intermediate Upward 30-45-60-75 yd", distance: 75, reps: 4, rest: 185, focus: "15-Yard Progression", level: "Intermediate", sessionType: .sprint),
    
    // Advanced Upward Pyramids (331-340)
    SprintSessionTemplate(id: 331, name: "Advanced Upward 20-40-60-80 yd", distance: 80, reps: 4, rest: 200, focus: "Power Distance", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 332, name: "Advanced Upward 25-50-75-100 yd", distance: 100, reps: 4, rest: 240, focus: "Quarter Mile Build", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 333, name: "Advanced Upward 30-50-70-90-110 yd", distance: 110, reps: 5, rest: 250, focus: "20-Yard Steps", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 334, name: "Advanced Upward 40-60-80-100-120 yd", distance: 120, reps: 5, rest: 270, focus: "Elite Distance Build", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 335, name: "Advanced Upward 35-55-75-95 yd", distance: 95, reps: 4, rest: 220, focus: "20-Yard Variable", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 336, name: "Advanced Upward 20-50-80-110 yd", distance: 110, reps: 4, rest: 260, focus: "30-Yard Jumps", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 337, name: "Advanced Upward 28-42-56-70-84 yd", distance: 84, reps: 5, rest: 200, focus: "14-Yard Multiples", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 338, name: "Advanced Upward 45-65-85-105 yd", distance: 105, reps: 4, rest: 245, focus: "20-Yard Variable", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 339, name: "Advanced Upward 30-60-90-120 yd", distance: 120, reps: 4, rest: 280, focus: "30-Yard Doubles", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 340, name: "Advanced Upward 25-45-65-85-105-125 yd", distance: 125, reps: 6, rest: 260, focus: "20-Yard Progressive", level: "Advanced", sessionType: .sprint),
    
    // Elite Upward Pyramids (341-350)
    SprintSessionTemplate(id: 341, name: "Elite Upward 30-60-90-120-150 yd", distance: 150, reps: 5, rest: 320, focus: "Elite Distance Progression", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 342, name: "Elite Upward 40-70-100-130-160 yd", distance: 160, reps: 5, rest: 340, focus: "30-Yard Elite Steps", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 343, name: "Elite Upward 50-100-150-200 yd", distance: 200, reps: 4, rest: 400, focus: "50-Yard Elite Jumps", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 344, name: "Elite Upward 35-70-105-140-175 yd", distance: 175, reps: 5, rest: 360, focus: "35-Yard Multiples", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 345, name: "Elite Upward 60-90-120-150-180 yd", distance: 180, reps: 5, rest: 380, focus: "30-Yard Elite Build", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 346, name: "Elite Upward 45-80-115-150 yd", distance: 150, reps: 4, rest: 340, focus: "35-Yard Variable", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 347, name: "Elite Upward 25-75-125-175 yd", distance: 175, reps: 4, rest: 360, focus: "50-Yard Leaps", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 348, name: "Elite Upward 55-85-115-145-175 yd", distance: 175, reps: 5, rest: 350, focus: "30-Yard Elite Steps", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 349, name: "Elite Upward 40-90-140-190 yd", distance: 190, reps: 4, rest: 380, focus: "50-Yard Elite Progression", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 350, name: "Elite Upward 70-105-140-175-210 yd", distance: 210, reps: 5, rest: 420, focus: "35-Yard Championship Build", level: "Elite", sessionType: .sprint),
    
    // MARK: - Downward Pyramids (351-400) - Build Down Only
    
    // Beginner Downward Pyramids (351-365)
    SprintSessionTemplate(id: 351, name: "Beginner Downward 25-15-5 yd", distance: 25, reps: 3, rest: 90, focus: "Speed to Acceleration", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 352, name: "Beginner Downward 30-20-10 yd", distance: 30, reps: 3, rest: 100, focus: "Distance Reduction", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 353, name: "Beginner Downward 35-25-15-5 yd", distance: 35, reps: 4, rest: 95, focus: "4-Step Descent", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 354, name: "Beginner Downward 40-30-20-10 yd", distance: 40, reps: 4, rest: 110, focus: "Classic Descent", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 355, name: "Beginner Downward 24-16-8 yd", distance: 24, reps: 3, rest: 85, focus: "Halving Pattern", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 356, name: "Beginner Downward 28-21-14-7 yd", distance: 28, reps: 4, rest: 90, focus: "7-Yard Descent", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 357, name: "Beginner Downward 35-20-5 yd", distance: 35, reps: 3, rest: 105, focus: "Large Step Down", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 358, name: "Beginner Downward 32-24-16-8 yd", distance: 32, reps: 4, rest: 95, focus: "8-Yard Descent", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 359, name: "Beginner Downward 25-20-15-10-5 yd", distance: 25, reps: 5, rest: 85, focus: "5-Step Descent", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 360, name: "Beginner Downward 30-25-20-15 yd", distance: 30, reps: 4, rest: 100, focus: "5-Yard Steps Down", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 361, name: "Beginner Downward 36-27-18-9 yd", distance: 36, reps: 4, rest: 105, focus: "9-Yard Descent", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 362, name: "Beginner Downward 40-25-10 yd", distance: 40, reps: 3, rest: 115, focus: "Variable Descent", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 363, name: "Beginner Downward 22-18-14-10-6 yd", distance: 22, reps: 5, rest: 80, focus: "4-Yard Steps Down", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 364, name: "Beginner Downward 35-28-21-14 yd", distance: 35, reps: 4, rest: 110, focus: "7-Yard Variable", level: "Beginner", sessionType: .sprint),
    SprintSessionTemplate(id: 365, name: "Beginner Downward 30-18-6 yd", distance: 30, reps: 3, rest: 100, focus: "12-Yard Descent", level: "Beginner", sessionType: .sprint),
    
    // Intermediate Downward Pyramids (366-380)
    SprintSessionTemplate(id: 366, name: "Intermediate Downward 60-45-30-15 yd", distance: 60, reps: 4, rest: 140, focus: "15-Yard Descent", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 367, name: "Intermediate Downward 75-50-25 yd", distance: 75, reps: 3, rest: 160, focus: "25-Yard Steps Down", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 368, name: "Intermediate Downward 70-55-40-25-10 yd", distance: 70, reps: 5, rest: 150, focus: "Variable Descent", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 369, name: "Intermediate Downward 80-60-40-20 yd", distance: 80, reps: 4, rest: 170, focus: "20-Yard Steps Down", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 370, name: "Intermediate Downward 65-52-39-26-13 yd", distance: 65, reps: 5, rest: 155, focus: "13-Yard Descent", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 371, name: "Intermediate Downward 90-70-50-30 yd", distance: 90, reps: 4, rest: 180, focus: "20-Yard Variable", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 372, name: "Intermediate Downward 72-54-36-18 yd", distance: 72, reps: 4, rest: 165, focus: "18-Yard Descent", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 373, name: "Intermediate Downward 85-65-45-25 yd", distance: 85, reps: 4, rest: 175, focus: "20-Yard Variable Down", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 374, name: "Intermediate Downward 60-48-36-24-12 yd", distance: 60, reps: 5, rest: 145, focus: "12-Yard Steps Down", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 375, name: "Intermediate Downward 100-75-50-25 yd", distance: 100, reps: 4, rest: 200, focus: "25-Yard Descent", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 376, name: "Intermediate Downward 77-63-49-35-21 yd", distance: 77, reps: 5, rest: 170, focus: "14-Yard Descent", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 377, name: "Intermediate Downward 95-70-45-20 yd", distance: 95, reps: 4, rest: 185, focus: "25-Yard Variable", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 378, name: "Intermediate Downward 66-55-44-33-22 yd", distance: 66, reps: 5, rest: 160, focus: "11-Yard Steps Down", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 379, name: "Intermediate Downward 84-63-42-21 yd", distance: 84, reps: 4, rest: 175, focus: "21-Yard Descent", level: "Intermediate", sessionType: .sprint),
    SprintSessionTemplate(id: 380, name: "Intermediate Downward 110-85-60-35-10 yd", distance: 110, reps: 5, rest: 190, focus: "Variable Large Descent", level: "Intermediate", sessionType: .sprint),
    
    // Advanced Downward Pyramids (381-390)
    SprintSessionTemplate(id: 381, name: "Advanced Downward 120-90-60-30 yd", distance: 120, reps: 4, rest: 240, focus: "30-Yard Descent", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 382, name: "Advanced Downward 150-100-50 yd", distance: 150, reps: 3, rest: 300, focus: "50-Yard Steps Down", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 383, name: "Advanced Downward 140-110-80-50-20 yd", distance: 140, reps: 5, rest: 260, focus: "30-Yard Variable Down", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 384, name: "Advanced Downward 160-120-80-40 yd", distance: 160, reps: 4, rest: 280, focus: "40-Yard Descent", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 385, name: "Advanced Downward 135-108-81-54-27 yd", distance: 135, reps: 5, rest: 270, focus: "27-Yard Descent", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 386, name: "Advanced Downward 180-135-90-45 yd", distance: 180, reps: 4, rest: 320, focus: "45-Yard Steps Down", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 387, name: "Advanced Downward 125-100-75-50-25 yd", distance: 125, reps: 5, rest: 250, focus: "25-Yard Steps Down", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 388, name: "Advanced Downward 170-130-90-50 yd", distance: 170, reps: 4, rest: 300, focus: "40-Yard Variable Down", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 389, name: "Advanced Downward 144-120-96-72-48 yd", distance: 144, reps: 5, rest: 280, focus: "24-Yard Steps Down", level: "Advanced", sessionType: .sprint),
    SprintSessionTemplate(id: 390, name: "Advanced Downward 200-150-100-50 yd", distance: 200, reps: 4, rest: 360, focus: "50-Yard Elite Descent", level: "Advanced", sessionType: .sprint),
    
    // Elite Downward Pyramids (391-400)
    SprintSessionTemplate(id: 391, name: "Elite Downward 200-150-100-50 yd", distance: 200, reps: 4, rest: 400, focus: "Elite 50-Yard Descent", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 392, name: "Elite Downward 250-180-110-40 yd", distance: 250, reps: 4, rest: 450, focus: "Elite Variable Descent", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 393, name: "Elite Downward 220-165-110-55 yd", distance: 220, reps: 4, rest: 420, focus: "55-Yard Steps Down", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 394, name: "Elite Downward 300-225-150-75 yd", distance: 300, reps: 4, rest: 500, focus: "75-Yard Elite Descent", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 395, name: "Elite Downward 175-140-105-70-35 yd", distance: 175, reps: 5, rest: 360, focus: "35-Yard Steps Down", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 396, name: "Elite Downward 280-210-140-70 yd", distance: 280, reps: 4, rest: 480, focus: "70-Yard Elite Steps", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 397, name: "Elite Downward 240-180-120-60 yd", distance: 240, reps: 4, rest: 440, focus: "60-Yard Descent", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 398, name: "Elite Downward 210-168-126-84-42 yd", distance: 210, reps: 5, rest: 400, focus: "42-Yard Steps Down", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 399, name: "Elite Downward 320-240-160-80 yd", distance: 320, reps: 4, rest: 520, focus: "80-Yard Elite Descent", level: "Elite", sessionType: .sprint),
    SprintSessionTemplate(id: 400, name: "Elite Downward 350-260-170-80 yd", distance: 350, reps: 4, rest: 560, focus: "Elite Championship Descent", level: "Elite", sessionType: .sprint)
]
