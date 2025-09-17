import Foundation

enum GameState: String, Codable {
    case active
    case gameOver = "game_over"
    case recovery
}

struct GameStateInfo: Codable {
    let state: GameState
    let health: Int
    let gameOverDate: Date?
    let recoveryStartedAt: Date?
    let recoveryDistance: Int?
    let recoveryTarget: Int?
    let recoveryPercentage: Int?
}

