#include "fir.h"

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial your fir

	for(int i=0; i<N; i++){
		inputbuffer[i] = 0;
		outputsignal[i] = 0;
	}
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	initfir();

	int Temp;
	int Data;

	for (int j = 0; j < N; j++) {
		int result = 0;
		Temp = inputsignal[j];

		for (int i = N - 1; i >= 0; i--) {
			if (i == 0) {
				inputbuffer[0] = Temp;
				Data = Temp;
			} else {
				inputbuffer[i] = inputbuffer[i - 1];
				Data = inputbuffer[i];
			}
			result += Data * taps[i];
		}
		outputsignal[j] = result;
	}
	return outputsignal;
}
		
