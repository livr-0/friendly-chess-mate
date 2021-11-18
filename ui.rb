# Draw game UI

def draw_ui
    draw_board()
    if @clicked_cell != nil
        highlight_clicked_cell()
    end
    if @move != nil
        highlight_legal_pos(@move.legal_to)
    end
end

# Draw chess board, including cells and their linked piece

def draw_board
    @cells.each{|cells_y| cells_y.each{|cell| 
        draw_cell(cell)
        if cell.linked_piece != nil
            cell.linked_piece.img.draw(cell.x, cell.y, ZOrder::PIECES, 1, 1, cell.linked_piece.c)
        end
        }
    }
end

# Draw a single cell

def draw_cell(cell)
    Gosu.draw_rect(cell.x, cell.y, cell.w, cell.h, cell.c, ZOrder::BOARD)
end

# Highlight clicked cell

def highlight_clicked_cell
    cell = @clicked_cell
    highlight_color = Gosu::Color::RED
    highlight_cell(cell, highlight_color)
end

# Highlight cells chosen piece can move to

def highlight_legal_pos(legal_pos)
    highlight_color = Gosu::Color::BLUE
    cells = []
    legal_pos.length.times do |i|
        @cells.length.times do |j|
            @cells[j].length.times do |k|
                if @cells[j][k].id == legal_pos[i] 
                    cells << @cells[j][k]
                end
            end
        end
    end
    cells.each{|cell| highlight_cell(cell, highlight_color)}
end

# Highlight a cell

def highlight_cell(cell, highlight_color)
    img = Gosu::Image.from_text("\u{2715}", cell.h, {:width => cell.w, :align => :center})
    x = cell.x
    y = cell.y
    z = cell.z
    img.draw(x, y, z, 1, 1, highlight_color)
end

# Is click on the game board?

def on_board?
    if mouse_x <= BOARD_WIDTH && mouse_y <= BOARD_HEIGHT; return true; end
end

# Return the cell a click is on

def on_cell?
    @cells.length.times do |y|
        @cells[y].length.times do |x|
            cell = @cells[y][x]
            if mouse_x.between?(cell.x, cell.x + cell.w) && mouse_y.between?(cell.y, cell.y + cell.h)
                return cell
            end
        end
    end
end