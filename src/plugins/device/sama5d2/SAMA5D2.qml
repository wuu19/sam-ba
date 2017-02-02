/*
 * Copyright (c) 2015-2016, Atmel Corporation.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 */

import QtQuick 2.3
import SAMBA 3.1
import SAMBA.Applet 3.1
import SAMBA.Device.SAMA5D2 3.1

/*!
	\qmltype SAMA5D2
	\inqmlmodule SAMBA.Device.SAMA5D2
	\brief Contains chip-specific information about SAMA5D2 device.

	This QML type contains configuration, applets and tools for supporting
	the SAMA5D2 device.

	\section1 Applets

	SAM-BA uses small programs called "Applets" to initialize the device or
	flash external memories. Please see SAMBA::Applet for more information on the
	applet mechanism.

	\section2 Low-Level Applet

	This applet is in charge of configuring the device clocks.

	It is only needed when using JTAG for communication with the device.
	When communication using USB or Serial via the SAM-BA Monitor, the clocks are
	already configured by the ROM-code.

	The only supported command is "init".

	\section2 SerialFlash Applet

	This applet is used to flash AT25 serial flash memories. It supports
	all SPI peripherals present on the SAMA5D2 device (see SAMA5D2Config for
	configuration information).

	Supported commands are "init", "read", "write" and "blockErase".

	\section2 QuadSPI Flash Applet

	This applet is used to flash QuadSPI memories. It supports both QSPI
	controllers present on the SAMA5D2 (see SAMA5D2Config for configuration
	information).

	Supported commands are "init", "read", "write" and "blockErase".

	\section2 NAND Applet

	This applet is used to flash NAND memories (see SAMA5D2Config for
	configuration information).

	Supported commands are "init", "read", "write" and "blockErase".

	\section2 SDMMC Applet

	This applet is used to read/write SD/MMC and e.MMC devices. It supports
	all SDMMC peripherals present on the SAMA5D2 device (see SAMA5D2Config
	for configuration information).

	Supported commands are "init", "read" and "write".

	\section1 Configuration

	When creating an instance of the SAMA5D2 type, some configuration can
	be supplied. The configuration parameters are then used during applet
	initialization where relevant.

	The configuration can be set either by selecting a preset board, or by
	setting custom values. If both board and custom values are set, the board
	settings are used.

	\section2 Board selection

	A set of pre-configured values can be selected by changing the 'board'
	property. For example, the following QML snipplet selects the SAMA5D2
	Xplained Ultra board:

	\qml
	SAMA5D2 {
		board: "sama5d2-xplained"
	}
	\endqml

	\section2 Custom configuration

	Each configuration value can be set individually.  Please see
	SAMA5D2Config for details on the configuration values.

	For example, the following QML snipplet configures a device using SPI1
	on I/O set 2 and Chip Select 3 at 33Mhz:

	\qml
	SAMA5D2 {
		config {
			serialflash {
				instance: 1
				ioset: 2
				chipSelect: 3
				freq: 33
			}
		}
	}
	\endqml
*/
Device {
	name: "sama5d2"

	aliases: [ "sama5d21", "sama5d22", "sama5d23", "sama5d24",
	           "sama5d26", "sama5d27", "sama5d28" ]

	description: "SAMA5D2x series"

	boards: [ "sama5d2-xplained" ]

	/*!
		\brief The device configuration used by applets (peripherals, I/O sets, etc.)
		\sa SAMA5D2Config
	*/
	property alias config: config

	applets: [
		SAMA5D2BootConfigApplet {
			codeUrl: Qt.resolvedUrl("applets/applet-bootconfig_sama5d2-generic_sram.bin")
			codeAddr: 0x220000
			mailboxAddr: 0x220004
		},
		LowlevelApplet {
			codeUrl: Qt.resolvedUrl("applets/applet-lowlevel_sama5d2-generic_sram.bin")
			codeAddr: 0x220000
			mailboxAddr: 0x220004
		},
		SerialFlashApplet {
			codeUrl: Qt.resolvedUrl("applets/applet-serialflash_sama5d2-generic_sram.bin")
			codeAddr: 0x220000
			mailboxAddr: 0x220004
		},
		QSPIFlashApplet {
			codeUrl: Qt.resolvedUrl("applets/applet-qspiflash_sama5d2-generic_sram.bin")
			codeAddr: 0x220000
			mailboxAddr: 0x220004
		},
		NANDFlashApplet {
			codeUrl: Qt.resolvedUrl("applets/applet-nandflash_sama5d2-generic_sram.bin")
			codeAddr: 0x220000
			mailboxAddr: 0x220004
			nandHeaderHelp: "For information on NAND header values, please refer to SAMA5D2 datasheet section \"15.4.6 Detailed Memory Boot Procedures\"."
		},
		SDMMCApplet {
			codeUrl: Qt.resolvedUrl("applets/applet-sdmmc_sama5d2-generic_sram.bin")
			codeAddr: 0x220000
			mailboxAddr: 0x220004
		}
	]

	/*!
		\brief Initialize the SAMA5D2 device using the given \a connection.

		This method calls checkDeviceID and then reconfigures the
		L2-Cache as SRAM for use by the applets.
	*/
	function initialize(connection) {
		checkDeviceID(connection)

		// Reconfigure L2-Cache as SRAM
		var SFR_L2CC_HRAMC = 0xf8030058
		connection.writeu32(SFR_L2CC_HRAMC, 0)
	}

	/*!
		\brief Checks that the device is a SAMA5D2.

		Reads CHIPID_CIDR register using the given \a connection and display
		a warning if its value does not match the expected value for SAMA5D2.
	*/
	function checkDeviceID(connection) {
		// read CHIPID_CIDR register
		var cidr = connection.readu32(0xfc069000)
		// Compare cidr using mask to skip revision field.
		// The right part of the expression is masked in order to be converted
		// to a signed integer like the left part (thanks javascript...)
		if ((cidr & 0xffffffe0) !== (0x8a5c08c0 & 0xffffffe0))
			print("Warning: Invalid CIDR, no known SAMA5D2 chip detected!")
	}

	onBoardChanged: {
		if (board === "" || typeof board === "undefined") {
			config.sdmmc.instance = undefined
			config.sdmmc.ioset = undefined
			config.sdmmc.partition = undefined
			config.sdmmc.busWidth = undefined
			config.sdmmc.voltages = undefined
			config.serialflash.instance = undefined
			config.serialflash.ioset = undefined
			config.serialflash.chipSelect = undefined
			config.serialflash.freq = undefined
			config.nandflash.ioset = undefined
			config.nandflash.busWidth = undefined
			config.nandflash.header = undefined
			config.qspiflash.instance = undefined
			config.qspiflash.ioset = undefined
			config.qspiflash.freq = undefined
		}
		else if (board === "sama5d2-xplained") {
			config.sdmmc.instance = 0
			config.sdmmc.ioset = 1
			config.sdmmc.partition = 0
			config.sdmmc.busWidth = 0
			config.sdmmc.voltages = 1 + 4 /* 1.8V + 3.3V */
			config.serialflash.instance = 0
			config.serialflash.ioset = 1
			config.serialflash.chipSelect = 0
			config.serialflash.freq = 66
			config.nandflash.ioset = undefined
			config.nandflash.busWidth = undefined
			config.nandflash.header = undefined
			config.qspiflash.instance = 0
			config.qspiflash.ioset = 3
			config.qspiflash.freq = 66
		}
		else {
			var invalidBoard = board
			board = undefined
			throw new Error("Unknown SAMA5D2 board '" + invalidBoard + "'")
		}
	}

	SAMA5D2Config {
		id: config
	}
}
