# File description: This file contains information about the program's console, which hold the menu and a game (if there is one).

# Menu stores program's messages and buttons

class Menu
    attr_accessor :name, :x, :y, :z, :w, :h, :buttons, :bg_color, :messages, :msg_color
    def initialize(name, x, y, buttons, messages)
        @name = name
        @x = x 
        @y = y
        @buttons = buttons
        @messages = messages
        @bg_color = Gosu::Color::BLACK
        @msg_color = Gosu::Color::WHITE
        @w = WINDOW_WIDTH
        @h = WINDOW_HEIGHT
        @z = ZOrder::CONSOLE
    end
end

# Buttons for program's action

class Button
    attr_accessor :x, :y, :name, :w, :z, :h, :color, :hover_color, :hover, :padding
    def initialize(name)
        @name = name
        @x = x
        @y = y
        @hover = false
        @w = Gosu::Image.from_text(@name, FONT_HEIGHT).width
        @h = FONT_HEIGHT
        @padding = @h/2
        @z = ZOrder::CONSOLE
        @color = Gosu::Color::BLUE
        @hover_color = Gosu::Color::RED
    end
end

# Draw the console that has the menu and the game (if there is one)

def draw_console()
    Gosu.draw_rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, Gosu::Color::BLACK, ZOrder::CONSOLE)
    draw_menu(@menu)
    if @in_game
        draw_game()
    end
end

# Manage console (basically program manager)

def console_manager()
    update_messages()
    msg_h = Gosu::Image.from_text(@menu.messages, FONT_HEIGHT, {:width => @menu.w, :align => :center}).height
    @menu.buttons.length.times do |b|
            btn = @menu.buttons[b]
            btn.x = @menu.x + (@menu.w - btn.w)/2
            btn.y = @menu.y + msg_h + btn.h*b
        if mouse_x > btn.x && mouse_x < btn.x + btn.w && mouse_y > btn.y && mouse_y < btn.y + btn.h
            btn.hover = true
        else
            btn.hover = false
        end
    end
    if @in_game 
        update_game()
    end
end

# Event handler (in the current program, there is only left-click event)

def click_handler
    if @in_game
        if on_board?()
            cell = on_cell?()
            clicked_cell_handler(cell)
        end
    end
    @menu.buttons.each {|btn|
        if btn.hover 
            case btn.name 
            when 'start'
                start_game()
            when 'play again'
                start_game()
            when 'back'
                back()
            when 'exit'
                exit()
            when 'give up'
                end_game()
            end
        end
    }
end

# Set_up all the menus, buttons and other elements for handling user's input

def setup_menus()
    start_button = Button.new('start')
    exit_button = Button.new('exit')
    back_button = Button.new('back')
    play_again_button = Button.new('play again')
    give_up_button = Button.new('give up')

    messages = "Welcome to Friendly Chess Mate.\nClick start to proceed and enjoy the game\nor exit to exit the program.\n"
    start_menu = Menu.new('start', 0, WINDOW_HEIGHT/6, [start_button, exit_button], messages)

    messages = "w turn\n"
    game_menu = Menu.new('game', 0, BOARD_HEIGHT, [give_up_button, back_button], messages)

    messages = "Hope you enjoyed the game.\nClick to play again.\nor exit\n"
    endgame_menu = Menu.new('endgame', 0, WINDOW_HEIGHT/4, [play_again_button, exit_button], messages)

    return [start_menu, game_menu, endgame_menu]
end

# All buttons' functions

    # Start a new game

def start_game()
    @menu = @menus.find {|menu| menu.name == 'game'}
    @in_game = true
    init_game()
end

    # Go back to previous menu

def back()
    @menu = @menus[@menus.index(@menu) - 1]
    if @in_game 
        @in_game = false 
    end
end

    # End current game

def end_game
    @menu = @menus.find{|menu| menu.name == 'endgame'}
    @menu.messages = "Game ended on " + @turn + "'s turn.\n" + @move_log.length.to_s + " moves were made before ending.\n"
    @in_game = false
end

# Update messages based on the current game

def update_messages
    if @in_game
        @menu.messages = @turn + " turn"
        if @checkmate 
            @menu.messages += ". You lost. Better admit defeat and click give up."
        elsif @stalemate 
            @menu.messages += ". You are in stalement. It's wise to click give up."
        elsif @check
            @menu.messages += ". Also, you're in check."
        else
            @menu.messages += "\n"
        end
    end
end

    # Exit the program

def exit()
    self.close!()
end

# Draw menu

def draw_menu(menu)
    Gosu.draw_rect(menu.x, menu.y, menu.w, menu.h, menu.bg_color, menu.z)
    display_message(menu.messages, menu.x, menu.y, menu.z, menu.msg_color)
    menu.buttons.each {|btn|
        if !btn.hover
            draw_button(btn, btn.color)
        else
            draw_button(btn, btn.hover_color)
        end
    }
end

    # Draw messages

def display_message(msg, x, y, z, color)
    msg = Gosu::Image.from_text(msg, FONT_HEIGHT, {:width => @menu.w, :align => :center})
    msg.draw(x, y, z, 1, 1, color)
end

    # Draw buttons

def draw_button(button, color)
    @font.draw_text(button.name, button.x, button.y, button.z, 1, 1, color)
end