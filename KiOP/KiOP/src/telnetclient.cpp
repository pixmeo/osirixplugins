
#include "telnetclient.h"

//#include <stdio.h>
//#include <iostream>
//#include <string>
//#include <QtGui>
//#include <QtNetwork>

using namespace std;

TelnetClient::TelnetClient(QWidget *parent, Qt::WFlags flags)
	: QMainWindow(parent, flags)
{

	tcpSocket = new QTcpSocket(this);
    connect(tcpSocket, SIGNAL(connected()), this, SLOT(socketConnected()));
    connect(tcpSocket, SIGNAL(disconnected()), this, SLOT(socketDisconnected()));
	connect(tcpSocket, SIGNAL(error(QAbstractSocket::SocketError)), this, SLOT(displayError(QAbstractSocket::SocketError)));
	bufferSize = 0;

	tcpSocket->abort();
	//tcpSocket->connectToHost("localhost",17179);
}

void TelnetClient::connexion(){
	//if (!this->tcpSocket->isValid()){
		tcpSocket->connectToHost("localhost",17179);
		cout << "connexion!" << endl;
		//this->sendCommand(QString("\r\ndcmview2d:mouseLeftAction sessionStart\r\n"));
		//this->sendCommand(QString("\r\ndcmview2d:mouseLeftAction sessionStop\r\n"));
		//this->sendCommand(QString("\r\ndcmview2d:mouseLeftAction sessionStart\r\n"));
	//}
}

void TelnetClient::deconnexion(){
	//tcpSocket->write(QString("\r\ndcmview2d:mouseLeftAction sessionStop\r\n").toAscii());
	cout << "deconnexion!" << endl;
	//tcpSocket->disconnectFromHost();
}

void TelnetClient::sendCommand(QString cmd){//char cmd[]){
	//cout << "command: " << cmd.toStdString() << endl;
	QByteArray paquet = cmd.toAscii();
    //QDataStream out(&paquet, QIODevice::WriteOnly);

	//out << cmd;

    tcpSocket->write(paquet); // On envoie le paquet
}

void TelnetClient::socketConnected(){
	cout << "-- Connected to the server!" << endl;
}

void TelnetClient::socketDisconnected(){
	cout << "-- Disconnected!! ._. " << endl;
}

void TelnetClient::displayError(QAbstractSocket::SocketError socketError){
}