module SjuiTools
  module SwiftUI
    module Views
      module SpacingHelper
        # パディングを適用
        def apply_padding
          padding = @component['padding'] || @component['paddings']
          
          if padding
            # Ensure padding is converted to proper format
            if padding.is_a?(Array)
              case padding.length
              when 1
                add_modifier_line ".padding(#{padding[0].to_i})"
              when 2
                # 縦横のパディング
                add_modifier_line ".padding(.horizontal, #{padding[1].to_i})"
                add_modifier_line ".padding(.vertical, #{padding[0].to_i})"
              when 4
                # 上、右、下、左の順
                add_modifier_line ".padding(.top, #{padding[0].to_i})"
                add_modifier_line ".padding(.trailing, #{padding[1].to_i})"
                add_modifier_line ".padding(.bottom, #{padding[2].to_i})"
                add_modifier_line ".padding(.leading, #{padding[3].to_i})"
              end
            else
              add_modifier_line ".padding(#{padding.to_i})"
            end
          end
          
          # 個別のパディング設定（leftPadding, rightPadding, paddingLeft など）
          # paddingLeft と leftPadding の両方をサポート
          left_pad = @component['leftPadding'] || @component['paddingLeft']
          right_pad = @component['rightPadding'] || @component['paddingRight']
          top_pad = @component['topPadding'] || @component['paddingTop']
          bottom_pad = @component['bottomPadding'] || @component['paddingBottom']
          
          if left_pad
            add_modifier_line ".padding(.leading, #{left_pad.to_i})"
          end
          if right_pad
            add_modifier_line ".padding(.trailing, #{right_pad.to_i})"
          end
          if top_pad
            add_modifier_line ".padding(.top, #{top_pad.to_i})"
          end
          if bottom_pad
            add_modifier_line ".padding(.bottom, #{bottom_pad.to_i})"
          end
        end
        
        # マージンを適用（SwiftUIではGroup内でpaddingとして実装）
        def apply_margins
          left_margin = @component['leftMargin']
          right_margin = @component['rightMargin']
          top_margin = @component['topMargin']
          bottom_margin = @component['bottomMargin']
          margins = @component['margins']
          
          # marginsが配列で指定されている場合
          if margins
            if margins.is_a?(Array)
              case margins.length
              when 1
                # 全方向同じマージン
                add_modifier_line ".padding(.all, #{margins[0].to_i})"
              when 2
                # 縦横のマージン
                add_modifier_line ".padding(.vertical, #{margins[0].to_i})"
                add_modifier_line ".padding(.horizontal, #{margins[1].to_i})"
              when 4
                # 上、右、下、左の順
                add_modifier_line ".padding(.top, #{margins[0].to_i})"
                add_modifier_line ".padding(.trailing, #{margins[1].to_i})"
                add_modifier_line ".padding(.bottom, #{margins[2].to_i})"
                add_modifier_line ".padding(.leading, #{margins[3].to_i})"
              end
            else
              add_modifier_line ".padding(.all, #{margins.to_i})"
            end
          else
            # 個別のマージン設定
            if top_margin
              add_modifier_line ".padding(.top, #{top_margin.to_i})"
            end
            if bottom_margin
              add_modifier_line ".padding(.bottom, #{bottom_margin.to_i})"
            end
            if left_margin
              add_modifier_line ".padding(.leading, #{left_margin.to_i})"
            end
            if right_margin
              add_modifier_line ".padding(.trailing, #{right_margin.to_i})"
            end
          end
        end
        
        # insetsプロパティを適用（パディングの別形式）
        def apply_insets
          # insets プロパティ（パディングの別形式）
          if @component['insets']
            insets = @component['insets']
            if insets.is_a?(Array)
              case insets.length
              when 1
                add_modifier_line ".padding(#{insets[0].to_i})"
              when 2
                # 縦横のinsets
                add_modifier_line ".padding(.vertical, #{insets[0].to_i})"
                add_modifier_line ".padding(.horizontal, #{insets[1].to_i})"
              when 4
                # 上、右、下、左の順
                add_modifier_line ".padding(.top, #{insets[0].to_i})"
                add_modifier_line ".padding(.trailing, #{insets[1].to_i})"
                add_modifier_line ".padding(.bottom, #{insets[2].to_i})"
                add_modifier_line ".padding(.leading, #{insets[3].to_i})"
              end
            else
              add_modifier_line ".padding(#{insets.to_i})"
            end
          end
          
          # insetHorizontal プロパティ
          if @component['insetHorizontal']
            add_modifier_line ".padding(.horizontal, #{@component['insetHorizontal'].to_i})"
          end
        end
      end
    end
  end
end