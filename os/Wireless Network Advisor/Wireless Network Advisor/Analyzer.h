//
//  Analyzer.h
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-19.
//

#ifndef Analyzer_h
#define Analyzer_h

#include <pcap.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/ip.h>    // for struct ip
#include <netinet/tcp.h>   // for struct tcphdr

#include <stdio.h>
void packet_handler(u_char *user_data, const struct pcap_pkthdr *pkthdr, const u_char *packet);

void start_capture(const char *dev);

#endif /* Analyzer_h */
