require './comps.rb'
require './ui.rb'
require './logic.rb'

# The move object. A move is a change is position with or without a trailing effect. 
# It stores information about the piece on which that move is executed, possible positions based on current game state, the change in position, and trailing effect. 
# A move is pseudo if it does not have a destination for the piece on which it is executed and therefore, illegal.

class Move
    attr_accessor :on, :from, :to, :pseudo, :legal_to, :turn, :trailing, :trailing_pos, :trailing_state
    def initialize(on, turn)
        @on = on 
        @turn = turn
        @from = on.pos
        @pseudo = true
        @legal_to = @to = nil
        @trailing = @trailing_pos = @trailing_state = nil
    end
end

# Initialize all basic components of a game: board, pieces and game controllers

def init_game
    @cells = init_board()
    @pieces = init_pieces()
    init_controllers()
end

# Initialize game controllers, which control the flow of the game

def init_controllers
    @turn = 'w'; @king_pos = 'E1'
    @move = @clicked_cell = nil
    @check = @checkmate = false
    @move_log = []
    @legal_list = [[],[]]
end

# Update game components: cells and controllers and messages to users

def update_game
    update_board()
    alternate_turn()
    update_game_state()
end

# Draw game ui

def draw_game
    draw_ui()
end

# Make a move

def make_move(move)
    move.on.pos = move.to
    get_effect_for(move)
    move.on.moved = true
end

# Undo a move

def undo_move(move)
    move.on.pos = move.from 
    move.on.moved = false
    move.to = nil
    move.pseudo = true
    if move.trailing != nil
        reverse_effect(move)
    end
end

def reverse_effect(move)
    move.trailing.pos = move.trailing_pos
    move.trailing.dead = move.trailing_state
    move.trailing = move.trailing_pos = move.trailing_state = nil
end

# Detect clicked cell's intention

def clicked_cell_handler(cell)

    # Deselect cell
    if @clicked_cell == cell
        @clicked_cell = nil
        @move = nil

    # Or update new clicked cell
    else
        @clicked_cell = cell
        move_controller()
    end
 
end

# Control @move. Create a new move and push it to @move if the click triggers a new one, update if it triggers a pseudo and 

def move_controller()
    if new_move?()
        @move = Move.new(@clicked_cell.linked_piece, @turn)

        @move.legal_to = get_moves_for(@move.on)

        if @move.on.type == 'k'
            @move.legal_to.delete_if {|move| !(@legal_list[1].length != 0 && @legal_list[1].any?{|legal| move == legal})}
        elsif @move.on.type == 'p'  
            @move.legal_to = lead_to_check?(@move.legal_to.flatten.uniq.compact, -1, @king_pos).flatten.uniq.compact
            @move.legal_to.delete_if {|move| !(@legal_list[0].length != 0 && @legal_list[0].any?{|legal| move == legal})} 
        else
            @move.legal_to = lead_to_check?(@move.legal_to.flatten.uniq.compact, -1, @king_pos)
            @move.legal_to.delete_if {|move| !(@legal_list[0].length != 0 && @legal_list[0].any?{|legal| move == legal})}
        end
        
    elsif @move != nil && legal_move?(@clicked_cell.id)
        update_move(@clicked_cell.id)
        make_move(@move)
        @move_log << @move
        @move = nil
        @clicked_cell = nil
    else  
        @move = nil 
    end
end

# Detect new move

def new_move?
    if @move == nil && @clicked_cell.linked_piece != nil && @clicked_cell.linked_piece.side == @turn
        return true
    end
end

# Detect if a move is legal

def legal_move?(to)
    if @move.legal_to != nil && @move.legal_to.any?{|legal_to| to == legal_to}
        return true
    end
end

# Update the current move

def update_move(to)
    @move.to = to
    @move.pseudo = false
end