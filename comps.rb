# File description: This file contains information about the basic components of a chess game, including its pieces and board cells.

# Game settings

BOARD_WIDTH = 400; BOARD_HEIGHT = 400
CELL_COUNTS = 8
CELL_WIDTH = BOARD_WIDTH/CELL_COUNTS
CELL_HEIGHT = BOARD_HEIGHT/CELL_COUNTS
FILE = [nil, "A", "B", "C", "D", "E", "F", "G", "H"]

# Board cells

class Cell
    attr_accessor :x, :y, :z, :w, :h, :c, :id, :linked_piece
    def initialize(x, y, c, file, rank)
        @x = x
        @y = y
        @c = c
        @id = FILE[file] + rank.to_s
        @linked_piece = nil
        @z = ZOrder::BOARD
        @w = CELL_WIDTH
        @h = CELL_HEIGHT
    end
end

# Game pieces

class Piece
    attr_accessor :side, :type, :pos, :img, :c, :moved, :dead
    
    def initialize(side, type, pos)
        @side = side; @type = type; @pos = pos
        case @side
        when "w"
            case @type
            when "k"; code = "\u{2654}"
            when "q"; code = "\u{2655}"
            when "r"; code = "\u{2656}"
            when "b"; code = "\u{2657}"
            when "n"; code = "\u{2658}"
            when "p"; code = "\u{2659}"
            end
            @c = Gosu::Color::WHITE
        when "b"
            case @type
            when "k"; code = "\u{265A}"
            when "q"; code = "\u{265B}"
            when "r"; code = "\u{265C}"
            when "b"; code = "\u{265D}"
            when "n"; code = "\u{265E}"
            when "p"; code = "\u{265F}"
            end
            @c = Gosu::Color::BLACK
        end
        @img = Gosu::Image.from_text(code, CELL_HEIGHT, {:width => CELL_WIDTH, :align => :center})
        @moved = false
        @dead = false
    end

end

# Initialize the board, return the cells

def init_board
    cells = []
    CELL_COUNTS.times do |y|
        cells[y] = []
        CELL_COUNTS.times do |x|
            file = x + 1
            rank = y + 1
            if x % 2 == y % 2
                c = Gosu::Color::GRAY
            elsif x % 2 != y % 2
                c = Gosu::Color::GREEN
            end
            cell_x = CELL_WIDTH*x
            cell_y = CELL_HEIGHT*y
            cells[y] << Cell.new(cell_x, cell_y, c, file, rank)
        end
    end
    return cells
end

# Initialize pieces at the beginning of the game

def init_pieces
    pieces = []
    
    pieces << Piece.new("w", "k", "E1") # White King
    pieces << Piece.new("w", "q", "D1") # White Queen
    pieces << Piece.new("b", "k", "E8") # Black King
    pieces << Piece.new("b", "q", "D8") # Black Queen

    2.times do |i|

        pieces << Piece.new("w", "r", FILE[7*i + 1] + "1") # White Rooks
        pieces << Piece.new("b", "r", FILE[7*i + 1] + "8") # Black Rooks

        pieces << Piece.new("w", "n", FILE[5*i + 2] + "1") # White Knights
        pieces << Piece.new("b", "n", FILE[5*i + 2] + "8") # Black Knights

        pieces << Piece.new("w", "b", FILE[3*i + 3] + "1") # White Bishops
        pieces << Piece.new("b", "b", FILE[3*i + 3] + "8") # Black Bishops

    end

    8.times do |i|
        pieces << Piece.new("w", "p", FILE[i + 1] + "2") # White Pawns
        pieces << Piece.new("b", "p", FILE[i + 1] + "7") # Black Pawns
    end

    return pieces
end

# Update board, link cells with pieces

def update_board
    @cells.each {|cells_y| cells_y.each{|cell| link_with_piece(cell)}}
end

# Link cell and the piece standing on it

def link_with_piece(cell)
    cell.linked_piece = nil
    @pieces.length.times do |p|
        if !@pieces[p].dead && @pieces[p].pos == cell.id
            cell.linked_piece = @pieces[p]
        end
    end 
end