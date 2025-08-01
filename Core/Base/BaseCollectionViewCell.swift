import UIKit
import SwiftJsonUI

class BaseCollectionViewCell: SJUICollectionViewCell {
    
    // セルのインデックス位置を管理するプロパティ
    var index: Int = 0
    
    // プログラムで生成されるセルの初期化メソッド
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // Storyboard/XIBから生成されるセルの初期化メソッド
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Auto Layoutでセルサイズを自動計算する際に呼ばれるメソッド
    // レイアウト属性をそのまま返すことで、Auto Layoutによるサイズ計算を有効にする
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
}
