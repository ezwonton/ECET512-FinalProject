#include <iostream>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <arpa/inet.h> 
#include <signal.h>

#include <iostream>
#include <fstream>

#include <dirent.h>

#define numMultipath 2 
#define DYSE_GUI_IP "192.168.1.243"
#define DYSE_GUI_PORT 5000
#define DYSE_VSU_IP "192.168.1.233"
#define DYSE_VSU_PORT 5000
#define DYSE_CLIENT_PORT 5001
#define INIT_COMMAND 'I'
#define DYSE_STATUS_GOOD 'K'
#define DYSE_STATUS_BAD 'X' 

    // Will need to somehow get status to see when DYSE is ready
#define UPDATE_COMMAND 'U'
#define BATCH_COMMAND 'E'
#define BEGIN_COMMAND 'B'
#define RESET_COMMAND 'R'
#define QUIT_COMMAND 'Q'

#define LOCK_FILE "/mnt/dyse_config/status/DYSE_IN_USE.txt"
#define STATUS_FILE "/mnt/dyse_config/status/DYSE_STATUS.txt"
#define STATUS_LOADED_FILE "/mnt/dyse_config/status/DYSE_STATUS_LOADED.txt"
#define EMULATION_DONE_FILE "/mnt/dyse_config/status/DYSE_EMULATION_DONE.txt"

#define DEFAULT_CONFIG "config_2x2.xml"
#define DEFAULT_SCENARIO "baseScenario-2.txt"


std::ofstream lockFile;
std::ofstream statusFile;
char configFile[80];
char scenarioFile[80];
static bool running = true;

static void handleSignal(int)
{
    running = false;
    std::cin.clear();
    std::cout << "CTRL-C received. Suggest reset if emulation initiated, but not yet started." << std::endl;
/*
    if( fileExists(STATUS_LOADED_FILE) && !fileExists(STATUS_FILE) )
        std::cout << "Emulation may be in process of starting - suggest Reset\n";

*/
    exit(1);
}


struct CoeffMap
{
    int numTx;
    int numRx;
    double Gain;
    double Delay;
    double Doppler;
    double Phi;
    
    double multipathGain[numMultipath];
    double multipathDelay[numMultipath];

};

/*
bool fileExists(const char *filename)
{
  FILE *myFile = fopen( filename, "r");
  if( myFile == 0 )
     std::cout << "File is not readable\n";
  else
  {
     std::cout << "File is readable\n";
     fclose(myFile);
  }

  std::ifstream ifile(filename);
  std::cout << "ifile =" << ifile << std::endl;
  
  return (bool)ifile;
}
*/

int runSysCommand(const char *command)
{
    FILE *fpipe;
    char c = 0;
    int numChar = 0;
    if (0 == (fpipe = (FILE*)popen(command, "r")))
    {
        perror("popen() failed.");
        exit(1);
    }

    while (fread(&c, sizeof c, 1, fpipe))
    {
    //    printf("%c", c);
        numChar++;
    }

    pclose(fpipe);
    return(numChar);
}

bool fileExists(const char *filename )
{
   int numChar = 0;
   char cmd[80];
   bool retVal;
   DIR *pDir;

   pDir = opendir( "/mnt/dyse/config/status" );
   strcpy(cmd, "ls ");
   strcat(cmd, filename );
   strcat(cmd, " 2>/dev/null" );
   numChar=runSysCommand(cmd);
  // printf( "numChar = %d\n", numChar );
   retVal = (numChar > 0);
   closedir( pDir);
   return(retVal);
}

int openServer()
{
    int sockfd = 0, n = 0;
    struct sockaddr_in serv_addr;
    
    
    if((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        std::cout << "\n Error : Could not create socket \n";
        return(-1);
    } 

    memset(&serv_addr, '0', sizeof(serv_addr)); 

    serv_addr.sin_family = AF_INET;
    //serv_addr.sin_port = htons(DYSE_GUI_PORT); 
    serv_addr.sin_port = htons(DYSE_VSU_PORT);

 //   if(inet_pton(AF_INET, DYSE_GUI_IP, &serv_addr.sin_addr)<=0)
    if(inet_pton(AF_INET, DYSE_VSU_IP, &serv_addr.sin_addr)<=0)
    {
        std::cout << "\n inet_pton error occured\n"; 
        return(-1);
    } 

    if( connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0)
    {
       printf("Error : Connect Failed \n");
       return (-1);
    } 

    //printf( "Sockfd=%d\n", sockfd );
    return( sockfd );

}

int listenForAck( )
{
    int listenfd, connfd;
    struct sockaddr_in serv_addr;


    //printf("\nClient listening for connections \n");
    listenfd = socket(AF_INET, SOCK_STREAM, 0);
     // This code allows ctrl-c to disrupt socket accept
     int enable = 1;
     if (setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(int)) < 0)
          printf("setsockopt(SO_REUSEADDR) failed\n");
    memset(&serv_addr, '0', sizeof(serv_addr));

    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    serv_addr.sin_port = htons(DYSE_CLIENT_PORT);

    errno = bind(listenfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr));

    // Trying to accept only one connection at a time
    //   Should be doable by lock file, but some ops are too fast.
    listen(listenfd, 1);

    //printf( "Pre-accept - listenfd=%d\n", listenfd );
    connfd = accept(listenfd, (struct sockaddr*)NULL, NULL);
    //printf( "Post-accept - connfd=%d\n", connfd );


    close(listenfd);
    return( connfd );

}

int initialize_cmd( int sockfd )
{
    char cmd;
    int connfd;
    int err;
    std::cout << "Sending configuration file..." << std::endl;
    cmd = INIT_COMMAND;
    err=write(sockfd, &cmd, 1);
    err=write(sockfd, configFile, sizeof(configFile));
    if( err < 0)
        std::cout << "Error in send!" << std::endl;


    connfd = listenForAck();

    err=read(connfd, &cmd, 1 );
    close(connfd);
    if( err < 0 )
       std::cout << "Error in received acknowledgement" << std::endl;
    //if( !strcmp(cmd, DYSE_STATUS_GOOD) )
    if(cmd == DYSE_STATUS_GOOD )
    {
       std::cout << "... file read successfully" << std::endl;
       return(0);
    }
    else
    {
       std::cout << "... problem opening file" << std::endl;
       return(1);
    }
}

int reset_cmd( int sockfd )
{
    char cmd;
    int err;

    std::cout << "Sending reset command..." << std::endl;
    cmd = RESET_COMMAND;
    err=write(sockfd, &cmd, 1);
    if( err < 0)
        std::cout << "Error in send!" << std::endl;
    return err;
}

int quit_cmd( int sockfd )
{
    char cmd;
    int err;
    
    std::cout << "Sending quit command..." << std::endl;
    cmd = QUIT_COMMAND;
    err=write(sockfd, &cmd, 1);
    if( err < 0)
        std::cout << "Error in send!" << std::endl;
    return err;
}

int begin_cmd( int sockfd )
{
    char cmd;
    int err;

    std::cout << "Sending command to begin emulation..." << std::endl;
    std::cout << "  Monitor /mnt/dyse_config/status for more information\n";
    std::cout << "  Waiting for emulation complete signal from server\n";
    cmd = BEGIN_COMMAND;
    err=write(sockfd, &cmd, 1);
    if( err < 0)
        std::cout << "Error in send!" << std::endl;


    int connfd = listenForAck();
    
    err=read(connfd, &cmd, 1 );
    if( err < 0 )
       std::cout << "Error in received acknowledgement" << std::endl;
/*
    else
       std::cout << "Received ack = " << cmd << std::endl;
*/
    close(connfd);

    return err;
}


int batch_cmd( int sockfd )
{
    char cmd;
    int err;

    std::cout << "Sending scearnio file..." << std::endl;
    cmd = BATCH_COMMAND;
    err=write(sockfd, &cmd, 1);
    err=write(sockfd, scenarioFile, sizeof(scenarioFile));
    if( err < 0)
        std::cout << "Error in send!" << std::endl;

    // Wait for ack
    int connfd = listenForAck();

    err=read(connfd, &cmd, 1 );
    if( err < 0 )
       std::cout << "Error in received acknowledgement" << std::endl;
    close(connfd);
    //if( !strcmp(cmd, DYSE_STATUS_GOOD) )
    if( cmd == DYSE_STATUS_GOOD )
    {
       std::cout << "... file read successfully" << std::endl;
       return(0);
    }
    else
    {
       std::cout << "... problem opening file" << std::endl;
       return(1);
    }
}


int debugMode(  )
{
    struct CoeffMap myMap;
    int sockfd = 0;

    myMap.numTx = 0;
    myMap.numRx = 0;
    myMap.Gain = 0.0;
    myMap.Delay = 0.0;
    myMap.Doppler = 0.0;
    myMap.Phi = 0.0;

    // multipath ignored in debug mode
    myMap.multipathGain[0] = -90.0;
    myMap.multipathDelay[0] = 0.0;
    myMap.multipathGain[1] = -90.0;
    myMap.multipathDelay[1] = 0.0;

    char key = ' ';
    char cmd;
    int err;

/*

    strcpy( configFile, "/home/dyse/dyse_config/config/" );
    strcpy( scenarioFile, "/home/dyse/dyse_config/scenario/");

// Default values
    strcat( configFile, "config_2x2.xml" );
    strcat( scenarioFile, "handoffScenario-2bs-1ms-noShad-simple.txt");
*/


   std::cout << "Connecting to Server" << std::endl;
/*
    sockfd = openServer();
    if(sockfd<0)
    {
         std::cout << "Cannot connect to Server" << std::endl;
         return 1;
    }
*/

    while (key != 'q' && key != 'Q')
    {

        // Don't think it's right to have to re-open socket after TX, but
        // it works this way
 //       std::cout << "Connecting to Server" << std::endl;
        sockfd = openServer();
        if(sockfd<0)
        {
            std::cout << "Cannot connect to Server" << std::endl;
           return 1;
        }

        std::cout << std::endl << std::endl;
        std::cout << "I/i - Initialize DYSE configuration" << std::endl;
        std::cout << "E/e - Experimental scenario load" << std::endl;
        std::cout << "B/b - Begin emulation" << std::endl;
        std::cout << "U/u - Update" << std::endl;
        std::cout << "R/r - Reset/Stop" << std::endl;
        std::cout << "Q/q - Quit" << std::endl;
        std::cout << "Enter command: " << std::endl;
        std::cin >> key;



        switch (key)
        {
            case 'I':
            case 'i':
                err=initialize_cmd(sockfd);
                if( err ) 
                   std::cout << "Error in reading configuration file\n";
/*
                std::cout << "Initializing DYSE" << std::endl;
                cmd = INIT_COMMAND;
                err=write(sockfd, &cmd, 1);
                err=write(sockfd, configFile, sizeof(configFile)); 
                if( err < 0)
                    std::cout << "Error in send!" << std::endl;
*/
            break;

            case 'B':
            case 'b':
                err=begin_cmd(sockfd);
/*
                std::cout << "Beginning emulation" << std::endl;
                cmd = BEGIN_COMMAND;
                err=write(sockfd, &cmd, 1);
                if( err < 0)
                    std::cout << "Error in send!" << std::endl;
*/
            break;

            case 'E':
            case 'e':
                err=batch_cmd(sockfd);
                if( err )
                   std::cout << "Error in reading scenario file\n";
 
/*
                std::cout << "Batch load..." << std::endl;
                cmd = BATCH_COMMAND;
                err=write(sockfd, &cmd, 1);
                err=write(sockfd, scenarioFile, sizeof(scenarioFile));
                if( err < 0)
                    std::cout << "Error in send!" << std::endl;
*/
            break;

            case 'U':
            case 'u':
                std::cout << "Update" << std::endl;
                std::cout << "Enter numTx: ";
                std::cin >> myMap.numTx;
                std::cout << "Enter numRx: ";
                std::cin >> myMap.numRx;
                std::cout << "Enter gain: ";
                std::cin >> myMap.Gain;
                cmd = UPDATE_COMMAND;
                err=write(sockfd, &cmd, 1);
                if( err < 0)
                    std::cout << "Error in sending cmd!" << std::endl;
                err=write(sockfd, &myMap, sizeof(struct CoeffMap));
                if( err < 0)
                    std::cout << "Error in sending coefficients" << std::endl;

    	      //  write(sockfd, &myMap, sizeof(struct CoeffMap));

            break;

            case 'R':
            case 'r':
                err=reset_cmd(sockfd);
/*
                std::cout << "Reset" << std::endl;
                cmd = RESET_COMMAND;
                err=write(sockfd, &cmd, 1);
                if( err < 0)
                    std::cout << "Error in send!" << std::endl;
*/
            break;

            case 'Q':
            case 'q':
                err=quit_cmd(sockfd);
/*
                std::cout << "Quitting" << std::endl;
                cmd = QUIT_COMMAND;
                err=write(sockfd, &cmd, 1);
                if( err < 0)
                    std::cout << "Error in send!" << std::endl;
*/
            break;
          }
          close(sockfd);
    }
    return 0;

}

int resetMode()
{
   int sockfd = 0;
   int err = 0;

   sockfd = openServer();
   err=initialize_cmd(sockfd);
   close(sockfd);
   if( err )
   {
     std::cout << "Error with configuration file\n";
     return(1);
   }
   sleep(1);
   sockfd = openServer();
   err=reset_cmd(sockfd);
   close(sockfd);
   sleep(1);
   sockfd = openServer();
   err=quit_cmd(sockfd);
   close(sockfd);
   return 0;
}


int runMode()
{
   int sockfd = 0;
   int err;
   // Need to gracefully handle server not running

   //std::cout << "Sending configuration information to DYSE\n";
   sockfd = openServer();
   err=initialize_cmd(sockfd);
   close(sockfd);
   if( err )
   {
       std::cout << "Error with configuration file\n";
       return(1);
   }
   sleep(2);

   //std::cout << "Sending scenario information to DYSE\n";
   sockfd = openServer();
   err=batch_cmd(sockfd);
   close(sockfd);
   if( err )
   {
       std::cout << "Error with scenario file\n";
       return(1);
   }
  /* std::cout << "Got out of batch_cmd\n" << std::endl;
   std::cout.flush();
*/
/*
   while( !fileExists(STATUS_LOADED_FILE) && running)
   {
      std::cout << "Waiting to see scenario file loaded...\n";  
      std::cout.flush();
      sleep( 3 );
   }
   
*/

   //std::cout << "Beginning emulation\n";
   sockfd = openServer();
   err=begin_cmd(sockfd);
   close(sockfd);

/*
   DIR *pDir;
   bool notReadyToExit = true;
   while( !fileExists(EMULATION_DONE_FILE) && notReadyToExit ) // took out running because it will crash the DYSE service to break if broken while waiting for emulation to start
   {
      pDir = opendir( "/mnt/dyse_config/status" );
      if(!fileExists(STATUS_FILE) )
          std::cout << "Emulation not started\n";
      else
      {
          // The following line should absolutely not be necessary
          //runSysCommand( "ls /mnt/dyse_config/status" );
          std::cout << "Emulation started - waiting to see emulation done file...\n";
          if( !running )  // Handle Ctrl-C when emulation is in progress
              notReadyToExit = false;
      }
      closedir(pDir);
      sleep( 3 );
   } 
*/
       //  This could take a really long time
       //    --- create file in status directory: DYSE_EMULATION_DONE.txt
       //  There absolutely needs to be a graceful way to break out of this with Ctrl-C

   sockfd = openServer();
   err=reset_cmd(sockfd);
   close(sockfd);
   sleep(1);

   sockfd = openServer();
   err=quit_cmd(sockfd);
   close(sockfd);
   std::cout << "Graceful exit.\n";
   return 0;


}

void print_help()
{
   printf("Drexel Wireless Systems Lab DYSE client\n" );
   printf("\nCommand line options\n" );
   printf("   -h :Help\n");

   printf("   -c <configFile> : Configuration file in the /mnt/dyse_config/config base directory on the grid nodes.  Modify these files predominantly to adjust the number of DYSE channels used and the center frequency of the emulation. Default=%s\n\n", DEFAULT_CONFIG);

   printf("   -s <scenarioFile> : RF Scenario file in the /mnt/dyse_config/scenario base directory on the grid nodes.  Modify these files predominantly to pre-load a schedule of emulated channels between different combinations of transmitters and receivers.  Make sure that the number of nodes in your scenario is consistent with whatever configuration file you use. Default = %s\n\n", DEFAULT_SCENARIO);

   printf("   -r : Connect to and then reset DYSE, and disconnect.  This can be a good first step in debugging if the DYSE enters an strange state.  Look at /var/log/vre.log on the VRE in case this doesn't work. Next debug step should be to stop and restart dyse service on VRE.  Last resort should be power cycling.\n\n");

   printf("   -i : Interactive debug mode (suggest you simultaneously look at /var/log/vre.log on VRE)\n\n");

   printf("   Monitor /mnt/dyse_config/status for the current state of the emulation\n");
   printf("   Make sure companion server application is running on the VSU\n" );

}


int main(int argc, char *argv[])
{

    int index;
    int config_set = 0;
    int scenario_set = 0;
    int debug_mode = 0;
    int reset_mode = 0;
    strcpy( configFile, "/home/dyse/dyse_config/config/" );
    strcpy( scenarioFile, "/home/dyse/dyse_config/scenario/");

    signal( SIGINT, &handleSignal );


    if( argc < 2 )
    {
       printf("Not enough command line parameters\n");
       print_help();
       return 1;
    }

    for( index=1; index < argc; index++ )
    {
                if (!strcmp(argv[index],"-c")) {
                    config_set = 1;
                    strcat( configFile, argv[index+1]);
                } else if (!strcmp(argv[index],"-s")) {
                    scenario_set = 1;
                    strcat( scenarioFile, argv[index+1]);
                } else if (!strcmp(argv[index],"-h")) {
                     print_help();
                     return 0;
                } else if (!strcmp(argv[index],"-r")) {
                    reset_mode = 1;
                } else if (!strcmp(argv[index],"-i")) {
                    debug_mode = 1;
                }
    }

    if (!config_set)
       strcat( configFile, DEFAULT_CONFIG );
    if (!scenario_set)
       strcat( scenarioFile, DEFAULT_SCENARIO );



    if( fileExists(LOCK_FILE) )
    {
      printf("DYSE lock file found - DYSE is already in use. Exiting\n" );
      return 1;
    }

    if ( debug_mode )
       return( debugMode( ) );

    if ( reset_mode )
       return( resetMode() );

    return( runMode() );

}
