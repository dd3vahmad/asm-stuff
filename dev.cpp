// Provided Main
#include <cstdlib>
#include <iostream>
#include <cstdio>
#include <fstream>
#include <string>

using namespace std;

extern "C" bool checkParams(int, char *[], int, char [], long long*);
extern "C" bool getWord(char [], int, bool*, long long*);
extern "C" bool checkWord(char [], char [], int*);
extern "C" void closeFile(long long);

int main(int argc, char* argv[]){
    static	const	unsigned int	MAXWORDLENGTH=20;
    long long fileDescriptorFile =0;
    char wordToCheck[MAXWORDLENGTH+1]; 
    char wordObtained[MAXWORDLENGTH+1]; 
    int totalWords = 0;

    if(!checkParams(argc, argv, MAXWORDLENGTH, wordToCheck, &fileDescriptorFile)){
        if(fileDescriptorFile != 0)
            closeFile(fileDescriptorFile);
        exit(0);
    }

    int check = 0;
    bool valid = false;
    while(getWord(wordObtained, MAXWORDLENGTH,  &valid, &fileDescriptorFile)){
        if(valid && checkWord(wordObtained, wordToCheck, &totalWords)){
            cout<<"Found: "<<wordToCheck<<" - "<<totalWords<<endl;
        }
    }

    cout<<"Total Instances of "<< wordToCheck <<" Found: "<< totalWords<<endl;
    closeFile(fileDescriptorFile);
    return 0;
}