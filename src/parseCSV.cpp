#include <iostream>
#include <string>
#include<algorithm>
#include <fstream>
#include <sstream>
#include <vector>
#include <iomanip>
#include <Rcpp.h>
#include <chrono>

using namespace std;
using namespace std::chrono;
using namespace Rcpp;

//currentrowval class
class currentrowval{
public:
  int mmsi;
  std::string basedatetime;
  float lat;
  float longitude;
  float sog;
  float cog;
  int heading;
  std::string vesselname;
  std::string imo;
  std::string callsign;
  std::string vesseltype;
  std::string status;
  std::string length;
  std::string width;
  std::string draft;
  std::string cargofile;

  currentrowval(int  mmsi1, std::string basedatetime1,float lat1, float longitude1, float sog1, float cog1,
    int heading1, std::string vesselname1, std::string imo1, std::string callsign1, std::string vesseltype1, std::string status1, std::string length1, std::string width1,std::string draft1,std::string cargofile1){
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
//vector of currentrowval objects to store csvtables
vector<currentrowval> csvtable;
//compare function to sort by time
bool comparetime(const currentrowval& r1, const currentrowval& r2){
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

// [[Rcpp::export]]
void parsefile(std::string filename,int interval,int variance){

  //import csv file to "file"
  ifstream file(filename.c_str());

  //skip first line of csv file (Skip Headers)
  std::string line;
  getline(file, line);

  //save headers for later
  std::string headers=line;

  //test if file was loaded
  if(line.empty()){
    std::cout<<"Error: file not loaded"<<endl;
    return;
  }else{
    std::cout<<"File Loaded..."<<endl;
    std::cout<<"Running..."<<endl;
  }








  //object to hold currentrowval data
  currentrowval* temp;


  //vector to hold currentrowval data
  vector<std::string> v;

  //auto start = high_resolution_clock::now();

  //loop through csv file
  while (getline(file, line)){


    //clear vector
    v.clear();

    //get current line value and add it to sting line then convert to string stream
    stringstream ss(line);

    //convert line into set of strings, store in vector v
    while (ss.good()) {
      std::string substr;
      getline(ss, substr, ',');

      v.push_back(substr);
    }


    //only add by 5 min itervals and ignore certain statuses

    //convert min and seconds to ints
    int tempint=stoi(v[1].substr(14,2));
    int tempint2=stoi(v[1].substr(17,2));



    //filter by type
    if(v[11]!=("at anchor")&&(v[11]!=("moored"))&&(v[11]!=("aground"))){

      //5 min interval
      if(tempint%interval==0){
        if(tempint2<=variance){
          temp=new currentrowval(stoi(v[0]),v[1],stof(v[2]),stof(v[3]),stof(v[4]),stof(v[5]),stoi(v[6]),v[7],v[8],v[9],v[10],v[11],v[12],v[13],v[14],v[15]);
          csvtable.push_back(*temp);
        }
      }else if(findclose(tempint,interval)){
        if(tempint2>=60-variance){
          temp=new currentrowval(stoi(v[0]),v[1],stof(v[2]),stof(v[3]),stof(v[4]),stof(v[5]),stoi(v[6]),v[7],v[8],v[9],v[10],v[11],v[12],v[13],v[14],v[15]);
          csvtable.push_back(*temp);

        }

      }
    }

  }

  cout<<"Parsed by "<< interval <<" min intervals"<<endl;

  //sort csvtable by mmsi
  //sort(csvtable.begin(), csvtable.end(), [](const currentrowval& lhs, const currentrowval& rhs) {
  //  return lhs.mmsi < rhs.mmsi;
  //});

  //cout<<"sorted by boat id"<<endl;
  //--------------------


  //sort boats by time --------
  int startindex=0;
  int endindex=0;
  int boatid=csvtable[0].mmsi;

  for(int i=0;i<csvtable.size();i++){

    if(boatid!=csvtable[i].mmsi||i==csvtable.size()-1){


      sort(csvtable.begin()+startindex, csvtable.begin()+endindex, comparetime);

      boatid=csvtable[i].mmsi;
      startindex=i;
      endindex=i;
    }else{
      endindex++;
    }
  }
  //cout<<"sorted by time"<<endl;
  //-------------------------

  //write to csv file ----------
  ofstream file_stream;

  file_stream.open ("soundparse.csv");

  //write headers to file
  file_stream<<headers<<endl;
  //loop through csvtable and write to file
  for(int i=0;i<csvtable.size();i++){
    currentrowval currentcurrentrowval=csvtable[i];
    file_stream<<currentcurrentrowval.mmsi<<",";
    file_stream<<currentcurrentrowval.basedatetime<<",";
    file_stream<<currentcurrentrowval.lat<<",";
    file_stream<<currentcurrentrowval.longitude<<",";
    file_stream<<currentcurrentrowval.sog<<",";
    file_stream<<currentcurrentrowval.cog<<",";
    file_stream<<currentcurrentrowval.heading<<",";
    file_stream<<currentcurrentrowval.vesselname<<",";
    file_stream<<currentcurrentrowval.imo<<",";
    file_stream<<currentcurrentrowval.callsign<<",";
    file_stream<<currentcurrentrowval.vesseltype<<",";
    file_stream<<currentcurrentrowval.status<<",";
    file_stream<<currentcurrentrowval.length<<",";
    file_stream<<currentcurrentrowval.width<<",";
    file_stream<<currentcurrentrowval.draft<<",";
    file_stream<<currentcurrentrowval.cargofile<<endl;


  }

  file_stream.close();
  //-------------------------

  //get time of run
  //auto stop = high_resolution_clock::now();
  //auto duration = duration_cast<seconds>(stop - start);
  //float time=duration.count()/60;
  //cout<<"Done."<<endl;
  //cout<<setprecision(2)<<"Elapsed Time: "<<(duration.count()-(duration.count()%60))/60<<":"<<duration.count()%60<<" minutes,seconds" << endl;
  //cout<<"number of records: "<<csvtable.size()-1<<endl;



}



