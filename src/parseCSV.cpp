#include <iostream>
#include <string>
#include<algorithm>
#include <fstream>
#include <sstream>
#include <vector>
#include <iomanip>
#include <Rcpp.h>

using namespace std;
using namespace Rcpp;


//global variables
    //column indexs of csv file
    int mmsiindex;
    int basedatetimeindex;
    int latindex; 
    int longitudeindex;
    int sogindex; 
    int cogindex;
    int headingindex;
    int vesselnameindex;
    int imoindex; 
    int callsignindex;
    int vesseltypeindex;
    int statusindex;
    int lengthindex; 
    int widthindex;
    int draftindex;
    int cargofileindex;


//-------------------------------------------------------
//csvrow class
class csvrow{
    public:
    int mmsi;
    string basedatetime;
    float lat; 
    float longitude;
    float sog; 
    float cog;
    int heading;
    string vesselname;
    string imo; 
    string callsign;
    string vesseltype;
    string status;
    string length; 
    string width;
    string draft;
    string cargofile;

    csvrow(int  mmsi1, string basedatetime1,float lat1, float longitude1, float sog1, float cog1,
    int heading1, string vesselname1, string imo1, string callsign1, string vesseltype1, string status1, string length1, string width1,string draft1,string cargofile1){
        mmsi=mmsi1;
        basedatetime=basedatetime1;
        lat=lat1;
        longitude=longitude1;
        sog=sog1;
        cog=cog1;
        heading=heading1;
        vesselname=vesselname1;
        imo=imo1;
        callsign=callsign1;
        vesseltype=vesseltype1;
        status=status1;
        length=length1;
        width=width1;
        draft=draft1;
        cargofile=cargofile1;        
    }

};

//compare function to sort by time
bool comparetime(const csvrow& r1, const csvrow& r2){

    int day1=stoi((r1.basedatetime).substr(8,2));
    int day2=stoi((r2.basedatetime).substr(8,2));
    int hour1=stoi((r1.basedatetime).substr(11,2));
    int hour2=stoi((r2.basedatetime).substr(11,2));
    int min1=stoi((r1.basedatetime).substr(14,2));
    int min2=stoi((r2.basedatetime).substr(14,2));
    int sec1=stoi((r1.basedatetime).substr(17,2));
    int sec2=stoi((r2.basedatetime).substr(17,2));

    // All cases when true should be returned 
    if (day1 < day2){ 
        return true; 
    }else if (day1 == day2 && hour1 < hour2){ 
        return true; 
    }else if (day1 == day2 && hour1 == hour2 && min1 < min2){ 
        return true;
    }else if(day1 == day2 && hour1 == hour2 && min1 == min2 && sec1<sec2){
        return true; 
    }
            
            
    return false; 
}

//determine if number is close to given interval
bool findclose(int a,int interval){
    int temp=0;
    while(temp<=a+1){
        if(a-temp==-1){
           
            return true;
        }else{
            temp+=interval;
        }

    }
    return false;
}
//-------------------------------------------------------



//look through csv headers and find the index of each the date and status
void findcolindexs(string line){
    vector<string> v;
    stringstream ss(line); 
    while (ss.good()) { 
        string substr; 
        getline(ss, substr, ',');   
        v.push_back(substr); 
    }
    int index=0;
    for(string x:v){
        
        if(x=="BaseDateTime"){
            basedatetimeindex=index;
       
        }else if(x=="Status"){
            statusindex=index;
        }

        index++;

    }
}

//method to parse csv

// [[Rcpp::export]]
void parsefile(string filename,int interval,int variance){
    

    //import csv file to "file"
    ifstream file(filename.c_str());

    //skip first line of csv file (Skip Headers)
    string line;
    getline(file, line);

    //save headers for later
    string headers=line;
    findcolindexs(line);

    //test if file was loaded
    if(line.empty()){
        cout<<"Error: file not loaded"<<endl;
        return;
    }


    //object to hold csvrow data
 


    //vector to hold csvrow data
    vector<string> v;

    //open file and write headers to it
    ofstream file_stream;
    file_stream.open ("soundparse.csv");
    file_stream<<headers<<endl;


    //loop through csv file
    while (getline(file, line)){
      
        
        //clear vector
        v.clear();

        //get current line value and add it to sting line then convert to string stream
        stringstream ss(line); 

        //convert line into set of strings, store in vector v
        while (ss.good()) { 
            string substr; 
            getline(ss, substr, ','); 
          
            v.push_back(substr); 
        }


        //only add by 5 min itervals and ignore certain statuses
        
        //convert min and seconds to ints
        int tempint=stoi(v[basedatetimeindex].substr(14,2));
        int tempint2=stoi(v[basedatetimeindex].substr(17,2));

        //filter by type
        if(v[statusindex]!=("at anchor")&&(v[statusindex]!=("moored"))&&(v[statusindex]!=("aground"))){
            
            //5 min interval
            if(tempint%interval==0){
               if(tempint2<=variance){
                    file_stream<<line<<"\n";
               }
            }else if(findclose(tempint,interval)){
                if(tempint2>=60-variance){
                    file_stream<<line<<"\n";
                }

            }
        }
 
    }



    

    file_stream.close();
    //------------------------- 

    
}



