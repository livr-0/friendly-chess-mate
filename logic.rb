# File description: procedures/functions below enforce the rules of the game, including legal moves constraints, turn alternation, etc.

# Alternate turn

def alternate_turn
    if @move_log.length != 0
        case @move_log[-1].turn 
        when 'w'
            @turn = 'b'
        when 'b'
            @turn = 'w'
        end
    end
end

# Update legal moves for all pieces in their turn

def update_game_state
    
    # Reset controllers

    @check = false; @legal_list = [[],[]]; opps = []

    @pieces.each {|piece|
        if !piece.dead 
            if piece.side == @turn && piece.type == 'k'
                @king_pos = piece.pos
                @legal_list[1] = get_moves_for(piece)
            elsif piece.side == @turn
                if get_moves_for(piece).length != 0
                    @legal_list[0] << get_moves_for(piece)
                end
            elsif piece.side != @turn
                opps << piece
            end
        end
    }

    # If a king is in check, all the allies (pieces of the same side) can only move to protect their king.

    @legal_list[0] = escape_check?(opps, 0, @legal_list[0].flatten.uniq.compact, @king_pos).flatten.uniq.compact

    # If a king is in check, it can move out of the checked position. 

    @legal_list[1] = rescue_itself(@legal_list[1].flatten.uniq.compact, 0).flatten.uniq.compact

    # If there are no possible moves for the king or its allies, it's checkmate for the player in turn.

    if @legal_list[0].length == 0 && @legal_list[1].length == 0 && @check 
        @checkmate = true
    end
end

# Reusable function to detect check 

def in_check?(king_pos)
    opps = @pieces.select{|p| p.side != @turn && !p.dead && p.type != 'k'}
    att_list = []
    opps.each {|o|
        att_list << get_capture_moves_for(o)
    }
    att_list = att_list.flatten.uniq.compact
    if att_list.any?{|att_pos| att_pos == king_pos}
        return true
    end
end

# Run through the entire list of opponent pieces and their attacks and try to find all the positions on the board where you can protect your king if it is attacked

def escape_check?(opps, n, legal_list, king_pos)
    if n == opps.length
        return legal_list
    else
        att_list = get_capture_moves_for(opps[n]).flatten.uniq.compact
        if att_list.all?{|att_pos| att_pos != king_pos}
            return escape_check?(opps, n+1, legal_list, king_pos)
        else
            @check = true

            # Narrow the att_list to those between the attacker and the king's position

            att_list = att_list.select{|att_pos| 
                (FILE.index(att_pos[0]).between?(FILE.index(opps[n].pos[0]) + 1, FILE.index(king_pos[0]) - 1) || FILE.index(att_pos[0]).between?(FILE.index(king_pos[0]) + 1, FILE.index(opps[n].pos[0]) - 1)) && (att_pos[1].to_i.between?(opps[n].pos[1].to_i + 1, king_pos[1].to_i - 1) || att_pos[1].to_i.between?(king_pos[1].to_i + 1, opps[n].pos[1].to_i - 1)) 
            }
            return escape_check?(opps, n+1, find_way_out(legal_list, opps[n], att_list), king_pos)
        end
    end
end

# Find a way to rescue your king

def find_way_out(legal_list, attacker, att_list)
    # You can

    legal_list.delete_if {|legal| 
        # Capture the attacker      or sacrifice yourself
        !(legal == attacker.pos || att_list.any?{|att_pos| att_pos == legal})

        # or standstill since you have no legal moves

    }

    return legal_list

end

# Go through the list of possible moves of the king and delete all that cannot bring it out of check

def rescue_itself(king_moves, n)
    if n == king_moves.length
        return king_moves
    else
        if in_check?(king_moves[n])
            king_moves[n] = nil
            return rescue_itself(king_moves, n+1)
        else
            return rescue_itself(king_moves, n+1)
        end
    end
end

# Go through a list of moves and delete all that lead to the king being in check

def lead_to_check?(legal_list, n, king_pos)
    if legal_list[n] == nil
        return legal_list
    else
        move = Move.new(@move.on, @turn)
        move.to = legal_list[n]
        make_move(move)
        update_board()
        if in_check?(king_pos)
            legal_list[n] = nil
            undo_move(move)
            update_board()
            return lead_to_check?(legal_list, n-1, king_pos)
        else
            undo_move(move)
            update_board()
            return lead_to_check?(legal_list, n-1, king_pos)
        end
    end
end

# Get the capture moves for a piece. 

def get_capture_moves_for(piece)
    moves = get_moves_for(piece)

    # Pawn has capture moves different from its forward moves

    if piece.type == 'p'
        moves.delete_if{|move| move[0] == piece.pos[0]}
        case piece.side
        when 'w'
            m = 1
        when 'b'
            m = -1
        end
        for i in [-1, 1]
            pos_file = FILE.index(piece.pos[0]) + i
            if pos_file.between?(1, CELL_COUNTS)
                moves << FILE[pos_file] + (piece.pos[1].to_i + m).to_s
            end
        end
    end 

    return moves.flatten.uniq.compact 
end

# Get basic moves for a piece

def get_moves_for(piece)
    case piece.type
    when "n"; return knight_move(piece)
    when "r"; return rook_move(piece)
    when "q"; return queen_move(piece)
    when "b"; return bishop_move(piece)
    when "p"; return pawn_move(piece)
    when "k"; return king_move(piece)
    end
end

# Get the trailing effect for a move

def get_effect_for(move)
    capture(move, move.to)
    case move.on.type
    when 'p'
        if en_passant?(move.from[1].to_i, move.on.side, FILE.index(move.to[0]))
            en_passant(move)
        elsif move == @move && pawn_promo?(move.on)
            pawn_promo(move.on)
        end
    when 'k'
        if castling?(move.on.moved, FILE.index(move.to[0]), FILE.index(move.from[0]), move.on.pos[1].to_i, move.on.side)
            castling(move)
        end
    end
end

# Basic moves for each piece type

def rook_move(piece)
    file = FILE.index(piece.pos[0])
    rank = piece.pos[1].to_i
    side = piece.side
    br = [[1, CELL_COUNTS], [1, CELL_COUNTS]]
    moves = []
    moves = straight_moves(file, rank, side, br)
    return moves.flatten.uniq.compact
end

def bishop_move(piece)
    file = FILE.index(piece.pos[0])
    rank = piece.pos[1].to_i
    side = piece.side
    br = [[1, CELL_COUNTS], [1, CELL_COUNTS]]
    moves = []
    moves = diagonal_moves(file, rank, side, br)
    return moves.flatten.uniq.compact
end

def queen_move(piece)
    file = FILE.index(piece.pos[0])
    rank = piece.pos[1].to_i
    side = piece.side
    br = [[1, CELL_COUNTS], [1, CELL_COUNTS]]
    moves = []
    straight_moves(file, rank, side, br).each {|move| moves << move}
    diagonal_moves(file, rank, side, br).each {|move| moves << move}
    return moves.flatten.uniq.compact
end 

def king_move(piece)
    file = FILE.index(piece.pos[0])
    rank = piece.pos[1].to_i
    side = piece.side
    br = [[rank - 1, rank + 1], [file - 1, file + 1]]
    moves = []
    straight_moves(file, rank, side, br).each {|move| moves << move}
    diagonal_moves(file, rank, side, br).each {|move| moves << move}

    moved = piece.moved
    for i in [-2, 2] do
        pos_file = file + i
        if castling?(moved, pos_file, file, rank, side)
            moves << FILE[pos_file] + rank.to_s
        end
    end

    opp_king_pos = @pieces.find{|p| p.side != piece.side && p.type == 'k'}.pos

    # Two kings must be 1 cell apart
    
    moves.delete_if{|move| (FILE.index(move[0]) - FILE.index(opp_king_pos[0])).abs < 2 && (move[1].to_i - opp_king_pos[1].to_i).abs < 2}

    return moves.flatten.uniq.compact
end

def knight_move(piece)
    file = FILE.index(piece.pos[0]); rank = piece.pos[1].to_i; side = piece.side
    moves = []

    for i in [-2, 2]
        pos_file = file + i
        for j in [-1, 1]
            pos_rank = rank + j
            if pos_file.between?(1, CELL_COUNTS) && pos_rank.between?(1, CELL_COUNTS)
                move = FILE[pos_file] + pos_rank.to_s
                moves << move
            end
        end
        pos_rank = rank + i
        for j in [-1, 1]
            pos_file = file + j
            if pos_file.between?(1, CELL_COUNTS) && pos_rank.between?(1, CELL_COUNTS)
                move = FILE[pos_file] + pos_rank.to_s
                moves << move
            end
        end
    end

    @pieces.each {|piece| 
        moves.delete_if { |move|
            !piece.dead && piece.pos == move && piece.side == side
        }
    }

    return moves.flatten.uniq.compact

end

def pawn_move(piece)

    file = FILE.index(piece.pos[0]); rank = piece.pos[1].to_i; side = piece.side
    moves = []
    
    # Detect the direction for forward moves. White moves 'up', black moves 'down' the board.

    case side 
    when 'w'
        multiplier = 1
    when 'b'
        multiplier = -1
    end

    # If pawn has not moves, it has an option to move one or two squares.

    if !piece.moved
        br = rank + multiplier*2
    else
        br = rank + multiplier*1
    end

    # Capture moves

    pos_file = file; pos_rank = rank
    pos_rank += multiplier
    for i in [-1, 1]
        pos_file = file + i
        if pos_file.between?(1, CELL_COUNTS) && pos_rank.between?(1, CELL_COUNTS)
            moves << FILE[pos_file] + pos_rank.to_s
            unless en_passant?(rank, side, pos_file)
                if @cells[pos_rank - 1][pos_file - 1].linked_piece == nil || @cells[pos_rank - 1][pos_file - 1].linked_piece.side == side
                    moves.pop()
                end
            end
        end
    end

    # Forward move

    pos_file = file; pos_rank = rank
    begin
        pos_rank += multiplier
        moves << FILE[pos_file] + pos_rank.to_s
        if pos_file.between?(1, CELL_COUNTS) && pos_rank.between?(1, CELL_COUNTS)
            if @cells[pos_rank - 1][pos_file - 1].linked_piece != nil
                br = pos_rank
                moves.pop()
            end
        else  
            br = pos_rank
        end
    end until pos_rank == br

    return moves.flatten.uniq.compact

end

# Trailing effects functions. Functions with '?' are conditions-checking functions. Capture is a more common effect than others, hence it does not have a separate condtion function.

def capture(move, pos)
    @pieces.each{|piece| 
        if piece != move.on && piece.pos == pos
            move.trailing = piece
            move.trailing_pos = piece.pos
            move.trailing_state = piece.dead
            piece.dead = true
        end
    }
end

def en_passant?(rank, side, pos_file)

    if rank != 5
        return false
    end

    piece = @cells[rank - 1][pos_file - 1].linked_piece
    
    if piece == nil || piece.dead || piece.side == side || piece.type != 'p'
        return false
    end

    if @move_log[-1].on != piece || (@move_log[-1].to[1].to_i - @move_log[-1].from[1].to_i).abs != 2
        return false
    end

    return true

end

def en_passant(move)
    capture(move, move.to[0] + move.from[1])
end

def castling?(moved, pos_file, file, rank, side)

    if in_check?(@king_pos)
        return false 
    end

    if moved 
        return false 
    end

    if pos_file > file 
        for btwn in (file + 1)..pos_file
            if @cells[rank - 1][btwn - 1].linked_piece != nil || in_check?(@cells[rank - 1][btwn - 1].id)
                return false
            end
        end
        rook = @pieces.find{|rook| !rook.dead && rook.type == 'r' && rook.side == side && !rook.moved && pos_file.between?(file, FILE.index(rook.pos[0]))}
        if rook == nil
            return false 
        end
        for btwn in (pos_file + 1)..(FILE.index(rook.pos[0]) - 1)
            if @cells[rank - 1][btwn - 1].linked_piece != nil
                return false
            end
        end
    elsif pos_file < file 
        for btwn in pos_file..(file - 1)
            if @cells[rank - 1][btwn - 1].linked_piece != nil || in_check?(@cells[rank - 1][btwn - 1].id)
                return false
            end
        end
        rook = @pieces.find{|rook| !rook.dead && rook.type == 'r' && rook.side == side && !rook.moved && pos_file.between?(FILE.index(rook.pos[0]), file)}
        if rook == nil
            return false
        end 
        for btwn in (FILE.index(rook.pos[0]) + 1)..(pos_file - 1)
            if @cells[rank - 1][btwn - 1].linked_piece != nil
                return false
            end
        end
    end

    return true
end

def castling(move)
    to_file = FILE.index(move.to[0]); from_file = FILE.index(move.from[0])
    if to_file > from_file 
        rook = @pieces.find{|rook| !rook.dead && rook.type == 'r' && rook.pos[1] == move.to[1] && to_file.between?(from_file, FILE.index(rook.pos[0]))}
        move.trailing = rook
        move.trailing_pos = rook.pos 
        move.trailing_state = rook.moved
        rook.pos[0] = FILE[(to_file + from_file)/2]
    elsif to_file  < from_file
        rook = @pieces.find{|rook| !rook.dead && rook.type == 'r' && rook.pos[1] == move.to[1] && to_file.between?(FILE.index(rook.pos[0]), from_file)}
        move.trailing = rook
        move.trailing_pos = rook.pos 
        move.trailing_state = rook.moved
        rook.pos[0] = FILE[(to_file + from_file)/2]
    end
end

def pawn_promo?(pawn)
    rank = pawn.pos[1]; side = pawn.side

    # Pawn on the other side of the board

    case side
    when 'b'
        if rank == '1'
            return true 
        end
    when 'w'
        if rank == CELL_COUNTS.to_s
            return true 
        end
    end
end

def pawn_promo(pawn)
    replace = Piece.new(pawn.side, 'q', pawn.pos)
    replace.moved = true 
    @pieces << replace 
    pawn.dead = true
end

# Basic straight and diagonal moves

def straight_moves(file, rank, side, br)

    moves = []
    pos_side = side 
    pos_br = [[],[]]
    pos_file = file; pos_rank = rank
    pos_br[0][0] = br[0][0]
    pos_br[0][1] = br[0][1]
    pos_br[1][0] = br[1][0]
    pos_br[1][1] = br[1][1]

    while pos_rank > pos_br[0][0] && pos_br[0][0].between?(1, CELL_COUNTS)
        pos_rank -= 1
        moves << FILE[pos_file] + pos_rank.to_s
        if @cells[pos_rank - 1][pos_file - 1].linked_piece != nil
            pos_br[0][0] = pos_rank
            if @cells[pos_rank - 1][pos_file - 1].linked_piece.side == pos_side
                moves.pop()
            end
        end
    end

    pos_file = file; pos_rank = rank
    while pos_rank < pos_br[0][1] && pos_br[0][1].between?(1, CELL_COUNTS)
        pos_rank += 1
        moves << FILE[pos_file] + pos_rank.to_s
        if @cells[pos_rank - 1][pos_file - 1].linked_piece != nil
            pos_br[0][1] = pos_rank
            if @cells[pos_rank - 1][pos_file - 1].linked_piece.side == pos_side
                moves.pop()
            end
        end
    end
    
    pos_file = file; pos_rank = rank
    while pos_file > pos_br[1][0] && pos_br[1][0].between?(1, CELL_COUNTS)
        pos_file -= 1
        moves << FILE[pos_file] + pos_rank.to_s
        if @cells[pos_rank - 1][pos_file - 1].linked_piece != nil
            pos_br[1][0] = pos_file
            if @cells[pos_rank - 1][pos_file - 1].linked_piece.side == pos_side
                moves.pop()
            end
        end
    end

    pos_file = file; pos_rank = rank
    while pos_file < pos_br[1][1] && pos_br[1][1].between?(1, CELL_COUNTS)
        pos_file += 1
        moves << FILE[pos_file] + pos_rank.to_s
        if @cells[pos_rank - 1][pos_file - 1].linked_piece != nil
            pos_br[1][1] = pos_file
            if @cells[pos_rank - 1][pos_file - 1].linked_piece.side == pos_side
                moves.pop()
            end
        end
    end
    return moves
end

def diagonal_moves(file, rank, side, br)

    moves = []
    pos_br = [[],[]]
    pos_file = file; pos_rank = rank; 
    pos_br[0][0] = br[0][0]
    pos_br[1][0] = br[1][0]

    while pos_rank > pos_br[0][0] && pos_file > pos_br[1][0] && pos_br[0][0].between?(1, CELL_COUNTS) && pos_br[1][0].between?(1, CELL_COUNTS)
        pos_rank -= 1; pos_file -= 1
        moves << FILE[pos_file] + pos_rank.to_s
        if @cells[pos_rank - 1][pos_file - 1].linked_piece != nil
            pos_br[0][0] = pos_rank
            pos_br[1][0] = pos_file
            if @cells[pos_rank - 1][pos_file - 1].linked_piece.side == side 
                moves.pop()
            end
        end
    end

    pos_file = file; pos_rank = rank
    pos_br[0][1] = br[0][1]
    pos_br[1][0] = br[1][0]
 
    while pos_rank < pos_br[0][1] && pos_file > pos_br[1][0] && pos_br[0][1].between?(1, CELL_COUNTS) && pos_br[1][0].between?(1, CELL_COUNTS)
        pos_rank += 1; pos_file -= 1
        moves << FILE[pos_file] + pos_rank.to_s
        if @cells[pos_rank - 1][pos_file - 1].linked_piece != nil
            pos_br[0][1] = pos_rank
            pos_br[1][0] = pos_file
            if @cells[pos_rank - 1][pos_file - 1].linked_piece.side == side 
                moves.pop()
            end
        end
    end
    
    pos_file = file; pos_rank = rank
    pos_br[0][0] = br[0][0]
    pos_br[1][1] = br[1][1]

    while pos_rank > pos_br[0][0] && pos_file < pos_br[1][1] && pos_br[0][0].between?(1, CELL_COUNTS) && pos_br[1][1].between?(1, CELL_COUNTS)
        pos_rank -= 1; pos_file += 1
        moves << FILE[pos_file] + pos_rank.to_s
        if @cells[pos_rank - 1][pos_file - 1].linked_piece != nil
            pos_br[0][0] = pos_rank
            pos_br[1][1] = pos_file
            if @cells[pos_rank - 1][pos_file - 1].linked_piece.side == side 
                moves.pop()
            end
        end
    end

    pos_file = file; pos_rank = rank
    pos_br[0][1] = br[0][1]
    pos_br[1][1] = br[1][1]

    while pos_rank < pos_br[0][1] && pos_file < pos_br[1][1] && pos_br[0][1].between?(1, CELL_COUNTS) && pos_br[1][1].between?(1, CELL_COUNTS)
        pos_rank += 1; pos_file += 1
        moves << FILE[pos_file] + pos_rank.to_s
        if @cells[pos_rank - 1][pos_file - 1].linked_piece != nil
            pos_br[0][1] = pos_rank
            pos_br[1][1] = pos_file
            if @cells[pos_rank - 1][pos_file - 1].linked_piece.side == side 
                moves.pop()
            end
        end
    end

    return moves

end