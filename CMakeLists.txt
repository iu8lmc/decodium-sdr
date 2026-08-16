cmake_minimum_required(VERSION 3.24)

project(decodium-sdr
    VERSION 1.2.5
    DESCRIPTION "DECODIUM SDR — client SDR universale dell'ecosistema DECODIUM"
    HOMEPAGE_URL "https://decodium.it"
    # Il C serve a RNNoise, che è l'unico codice C del progetto: senza,
    # i suoi sorgenti verrebbero ignorati in silenzio e la libreria uscirebbe
    # vuota — è già successo.
    LANGUAGES CXX C)

# Il nome della versione.
#
# Le versioni hanno un numero e un nome, e il nome serve a una cosa che il
# numero non sa fare: farsi ricordare. «Ce l'hai la 1.2.1 o la 1.1.13?» non se
# lo ricorda nessuno; «ce l'hai la Armstrong?» sì.
#
# **I nomi vanno in ordine alfabetico**, e questo li rende un numero
# progressivo a loro volta: dal nome si sa quale viene prima, senza consultare
# niente. È la stessa idea di Ubuntu e di Android, e funziona per la stessa
# ragione.
#
# Sono cognomi di chi ha fatto la radio. Il primo è Edwin **Armstrong** — la
# reazione, la supereterodina, la FM: l'uomo che ha reso i ricevitori
# utilizzabili, e che ha passato la vita a litigare su che cosa un circuito
# facesse *davvero*. Per una versione che è tutta strumenti di misura, non ce
# n'era uno più adatto.
#
# Chi taglia la prossima prende la lettera dopo: Colpitts, De Forest,
# Fessenden, Armstrong… La lettera è il numero d'ordine, e non si salta.
# È metadato di release, non una preferenza di chi compila: lasciarlo in cache
# farebbe sopravvivere il nome della versione precedente a un aggiornamento.
set(DSDR_VERSION_NAME "Goldsmith" CACHE STRING "Il nome di questa versione")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Tipo di build" FORCE)
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include(DsdrOptions)

find_package(Qt6 6.8 REQUIRED COMPONENTS
    Core Gui Network Qml Quick QuickControls2 Multimedia Concurrent
    ShaderTools Test QuickTest LinguistTools)

# QRhi è API pubblica di Qt Quick ma vive negli header privati di Qt Gui, e non
# tutte le distribuzioni espongono il componente CMake "GuiPrivate". Se manca,
# gli header si raggiungono per percorso: vedi dsdr_link_qt_rhi().
find_package(Qt6 6.8 QUIET OPTIONAL_COMPONENTS GuiPrivate)

qt_standard_project_setup(REQUIRES 6.8)

enable_testing()

# RNNoise, se chi compila ne ha messo il sorgente in third_party/. La
# capability dello stadio neurale nasce da qui: non c'è un fallback a runtime,
# perché una funzione che a volte c'è e a volte no è peggio di una che non c'è.
if(DSDR_NEURAL_NR)
    include(FindRnnoise)

    # Chi costruisce per altri non può perdere lo stadio neurale per strada.
    # Senza questo controllo il pacchetto esce con la riduzione di rumore
    # spenta e nessuno se ne accorge: il programma lo dice in una riga di log,
    # che su Windows un'applicazione con interfaccia non mostra a nessuno.
    # È andata così dalla 1.1.3 alla 1.1.8.
    if(DSDR_STRICT_BACKENDS AND NOT RNNOISE_FOUND)
        message(FATAL_ERROR
            "DSDR_NEURAL_NR è attivo ma RNNoise non c'è: il pacchetto uscirebbe "
            "senza la riduzione di rumore neurale.\n"
            "  git clone https://github.com/xiph/rnnoise third_party/rnnoise\n"
            "  cd third_party/rnnoise && ./download_model.sh\n"
            "Chi non la vuole compili con -DDSDR_NEURAL_NR=OFF, che è una "
            "scelta dichiarata invece di una funzione che sparisce.")
    endif()
endif()

add_subdirectory(src)

if(DSDR_BUILD_TESTS)
    add_subdirectory(tests)
endif()

# Il programma di installazione. Va per ultimo: CPack vuole sapere che cosa si
# installa, e lo sa solo dopo che i sottoprogetti hanno dichiarato i loro
# `install()`.
include(DsdrPackaging)

dsdr_print_configuration()
