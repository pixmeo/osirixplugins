#ifndef TELNETCLIENT_H
#define TELNETCLIENT_H

#include <QtGui/QMainWindow>
//#include "ui_testsocket.h"
#include <QtNetwork/qtcpsocket.h>
#include <stdio.h>
#include <iostream>
#include <string>

using namespace std;

QT_BEGIN_NAMESPACE
class QTcpSocket;
QT_END_NAMESPACE

class TelnetClient : public QMainWindow
{
	Q_OBJECT

public:
	TelnetClient(QWidget *parent = 0, Qt::WFlags flags = 0);
	void sendCommand(QString cmd);//char cmd[]);
	void connexion();
	void deconnexion();

protected:


private slots:
	void socketConnected();
	void socketDisconnected();
	void displayError(QAbstractSocket::SocketError socketError);

private:
	QTcpSocket *tcpSocket;
	QString message;
	quint16 bufferSize;
};


#endif //========================== FIN ====================================//







