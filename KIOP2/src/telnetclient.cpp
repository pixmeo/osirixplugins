#include <stdio.h>
#include <iostream>
#include <string>
#include <QtGui>
#include <QtNetwork>
#include "telnetclient.h"

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
	tcpSocket->connectToHost("localhost",17179);
}

void TelnetClient::deconnexion(){
	tcpSocket->disconnectFromHost();
}

void TelnetClient::sendCommand(QString cmd){//char cmd[]){

	QByteArray paquet = cmd.toAscii();
    //QDataStream out(&paquet, QIODevice::WriteOnly);

	//out << cmd;

    tcpSocket->write(paquet); // On envoie le paquet
}

void TelnetClient::socketConnected(){
	cout << "connected to the server!" << endl;
}

void TelnetClient::socketDisconnected(){
	cout << "disconnected!! ._. " << endl;
}

void TelnetClient::displayError(QAbstractSocket::SocketError socketError){
}