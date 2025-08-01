import UIKit
import SwiftJsonUI

@MainActor
class BaseBinding: Binding {
    // 初期化状態フラグ - 画面の初期化が完了したかを管理
//    var isInitialized: Bool = true
    
    // ナビゲーションタイトル文字列
//    var naviTitle: String?
    
    // ナビゲーションバーのビュー参照（weak参照でメモリリーク防止）
//    weak var navi: UIView!
    
    // タイトル表示用ラベルの参照（weak参照でメモリリーク防止）
//    weak var titleLabel: SJUILabel!
    
    // ナビゲーションタイトルの表示を更新するメソッド
    // リンク可能な場合はリンク付きテキスト、そうでなければ通常のテキストを適用
//    func invalidateNavi() {
//        titleLabel?.linkable ?? false ? titleLabel?.applyLinkableAttributedText(naviTitle) : titleLabel?.applyAttributedText(naviTitle)
//    }
}
