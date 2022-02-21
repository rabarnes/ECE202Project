# The following pong game implementation obtained from
# https://www.101computing.net/pong-tutorial-using-pygame-adding-a-scoring-system/


# Import the pygame library and initialise the game engine
import pygame
import threading 
from paddle import Paddle
from ball import Ball
from collections import deque
from debug_gui import App


def plotThread():
    app = App()
    app.begin()

def gameThread():
    game = pongGame(400,2,10)
    game.mainLoop()


class pongGame:
    
    def __init__(self, paddleLength=200, ballVelocity=1, paddleSpeed=5):
        # shared queue between game and data processing thread
        self.dataQueue = deque()
        self.paddleSpeed = paddleSpeed
        pygame.init() 
        # Define some colors
        self.BLACK = (0,0,0)
        self.WHITE = (255,255,255)
         
        # Open a new window
        size = (700, 500)
        self.screen = pygame.display.set_mode(size)
        pygame.display.set_caption("Pong")
         
        self.paddleA = Paddle(self.WHITE, 10, paddleLength)
        self.paddleA.rect.x = 20
        self.paddleA.rect.y = 200
         
        self.paddleB = Paddle(self.WHITE, 10, paddleLength)
        self.paddleB.rect.x = 670
        self.paddleB.rect.y = 200
         
        self.ball = Ball(self.WHITE,10,10,ballVelocity)
        self.ball.rect.x = 345
        self.ball.rect.y = 195
         
        #This will be a list that will contain all the sprites we intend to use in our game.
        self.all_sprites_list = pygame.sprite.Group()
         
        # Add the 2 paddles and the ball to the list of objects
        self.all_sprites_list.add(self.paddleA)
        self.all_sprites_list.add(self.paddleB)
        self.all_sprites_list.add(self.ball)
         
        # The loop will carry on until the user exits the game (e.g. clicks the close button).
        self.carryOn = True
         
        # The clock will be used to control how fast the screen updates
        self.clock = pygame.time.Clock()
         
        #Initialise player scores
        self.scoreA = 0
        self.scoreB = 0
    
    
    
    def mainLoop(self):
        # -------- Main Program Loop -----------
        while self.carryOn:
            # --- Main event loop
            for event in pygame.event.get(): # User did something
                if event.type == pygame.QUIT: # If user clicked close
                      self.carryOn = False # Flag that we are done so we exit this loop
                elif event.type==pygame.KEYDOWN:
                        if event.key==pygame.K_x: #Pressing the x Key will quit the game
                             self.carryOn=False
         
            #Moving the paddles when the use uses the arrow keys (player A) or "W/S" keys (player B) 
            keys = pygame.key.get_pressed()
            if keys[pygame.K_w]:
                self.paddleA.moveUp(self.paddleSpeed)
            if keys[pygame.K_s]:
                self.paddleA.moveDown(self.paddleSpeed)
            if keys[pygame.K_UP]:
                self.paddleB.moveUp(self.paddleSpeed)
            if keys[pygame.K_DOWN]:
                self.paddleB.moveDown(self.paddleSpeed)    
         
            # --- Game logic should go here
            self.all_sprites_list.update()
            
            #Check if the ball is bouncing against any of the 4 walls:
            if self.ball.rect.x>=690:
                self.scoreA+=1
                self.ball.velocity[0] = -self.ball.velocity[0]
            if self.ball.rect.x<=0:
                self.scoreB+=1
                self.ball.velocity[0] = -self.ball.velocity[0]
            if self.ball.rect.y>490:
                self.ball.velocity[1] = -self.ball.velocity[1]
            if self.ball.rect.y<0:
                self.ball.velocity[1] = -self.ball.velocity[1]     
         
            #Detect collisions between the ball and the paddles
            if pygame.sprite.collide_mask(self.ball, self.paddleA) or pygame.sprite.collide_mask(self.ball, self.paddleB):
              self.ball.bounce()
            
            # --- Drawing code should go here
            # First, clear the screen to black. 
            self.screen.fill(self.BLACK)
            #Draw the net
            pygame.draw.line(self.screen, self.WHITE, [349, 0], [349, 500], 5)
            
            #Now let's draw all the sprites in one go. (For now we only have 2 sprites!)
            self.all_sprites_list.draw(self.screen) 
         
            #Display scores:
            font = pygame.font.Font(None, 74)
            text = font.render(str(self.scoreA), 1, self.WHITE)
            self.screen.blit(text, (250,10))
            text = font.render(str(self.scoreB), 1, self.WHITE)
            self.screen.blit(text, (420,10))
         
            # --- Go ahead and update the screen with what we've drawn.
            pygame.display.flip()
             
            # --- Limit to 60 frames per second
            self.clock.tick(20)
         
        #Once we have exited the main program loop we can stop the game engine:
        pygame.quit()
        
    


if __name__ == "__main__":
    game = threading.Thread(target=gameThread)
    game.start()
    plot = threading.Thread(target=plotThread)
    plot.start()
    
    game.join()
    plot.join()
    