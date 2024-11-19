//
//  Analyzer.c
//  Wireless Network Advisor
//
//  Created by Owen Monus on 2024-11-19.
//

#include "Analyzer.h"

// Packet handler function
void packet_handler(u_char *user_data, const struct pcap_pkthdr *pkthdr, const u_char *packet) {
    // The packet starts here
    printf("Packet captured! Length: %d bytes\n", pkthdr->len);
    
    // Check for IP and TCP
    struct ip *ip_header = (struct ip *)(packet + 14);  // skip Ethernet header
    struct tcphdr *tcp_header = (struct tcphdr *)(packet + 14 + (ip_header->ip_hl * 4));  // skip IP header

    printf("Source IP: %s\n", inet_ntoa(ip_header->ip_src));
    printf("Destination IP: %s\n", inet_ntoa(ip_header->ip_dst));

    // Check for HTTP traffic (port 80) or HTTPS (port 443)
    if (ntohs(tcp_header->th_dport) == 80) {
        printf("HTTP traffic detected!\n");
    }
    else if (ntohs(tcp_header->th_dport) == 443) {
        printf("HTTPS traffic detected!\n");
    }
}

// Function to start capturing packets
void start_capture(const char *dev) {
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *handle;

    // Open the device for capturing packets
    handle = pcap_open_live(dev, BUFSIZ, 1, 1000, errbuf);
    if (handle == NULL) {
        fprintf(stderr, "Error opening device %s: %s\n", dev, errbuf);
        exit(1);
    }

    // Start packet capture loop
    if (pcap_loop(handle, 0, packet_handler, NULL) < 0) {
        fprintf(stderr, "Error capturing packets: %s\n", pcap_geterr(handle));
        exit(1);
    }

    // Close the capture handle when done
    pcap_close(handle);
}
