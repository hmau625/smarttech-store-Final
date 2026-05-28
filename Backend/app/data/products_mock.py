products = [
    {
        "id": 1,
        "name": "Intel Core i9-14900K",
        "category": "CPU",
        "brand": "Intel",
        "price": 2850000,
        "stock": 15,
        "specs": {
            "cores": 24,
            "threads": 32,
            "base_clock": "3.2GHz",
            "boost_clock": "6.0GHz",
            "socket": "LGA1700"
        },
        "image": "https://static0.pocketlintimages.com/wordpress/wp-content/uploads/2023/10/intel-core-i9-14900k.jpg?q=50&fit=crop&w=750&dpr=1.5"
    },
    {
        "id": 2,
        "name": "AMD Ryzen 9 7950X",
        "category": "CPU",
        "brand": "AMD",
        "price": 2700000,
        "stock": 10,
        "specs": {
            "cores": 16,
            "threads": 32,
            "base_clock": "4.5GHz",
            "boost_clock": "5.7GHz",
            "socket": "AM5"
        },
        "image": "https://http2.mlstatic.com/D_NQ_NP_2X_787534-MLA80608295721_112024-T.webp"
    },
    {
        "id": 3,
        "name": "NVIDIA RTX 4090 24GB",
        "category": "GPU",
        "brand": "NVIDIA",
        "price": 7800000,
        "stock": 5,
        "specs": {
            "memory": "24GB GDDR6X",
            "boost_clock": "2.52GHz",
            "ray_tracing": True
        },
        "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR906FzG-MDGj9ukFLIwcaIMNA9ys4qmaTKdg&s"
    },
    {
        "id": 4,
        "name": "Corsair Vengeance RGB 32GB",
        "category": "RAM",
        "brand": "Corsair",
        "price": 650000,
        "stock": 25,
        "specs": {
            "type": "DDR5",
            "speed": "6000MHz",
            "modules": "2x16GB"
        },
        "image": "https://http2.mlstatic.com/D_NQ_NP_637526-CBT50496319000_062022-O.webp"
    },
    {
        "id": 5,
        "name": "Samsung 990 PRO 2TB",
        "category": "SSD",
        "brand": "Samsung",
        "price": 900000,
        "stock": 20,
        "specs": {
            "type": "NVMe PCIe 4.0",
            "read_speed": "7450MB/s",
            "write_speed": "6900MB/s"
        },
        "image": "https://http2.mlstatic.com/D_NQ_NP_836224-CBT108256787816_032026-O.webp"
    },
    {
        "id": 6,
        "name": "ASUS ROG Strix B650-E",
        "category": "Motherboard",
        "brand": "ASUS",
        "price": 1200000,
        "stock": 8,
        "specs": {
            "socket": "AM5",
            "chipset": "B650",
            "ram_support": "DDR5"
        },
        "image": "https://dlcdnwebimgs.asus.com/files/media/42CF69C2-D16A-449F-A113-E7AB3C57AEE7/v1/img/spec/performance.png"
    },
    {
        "id": 7,
        "name": "Cooler Master 850W Gold",
        "category": "Power Supply",
        "brand": "Cooler Master",
        "price": 500000,
        "stock": 12,
        "specs": {
            "certification": "80+ Gold",
            "modular": True
        },
        "image": "https://http2.mlstatic.com/D_NQ_NP_675010-MLA99962574833_112025-O.webp"
    },
    {
        "id": 8,
        "name": "PC Gamer Ultra RTX 4080",
        "category": "Prebuilt PC",
        "brand": "SMARTECH",
        "price": 9500000,
        "stock": 3,
        "specs": {
            "cpu": "Intel i7-14700K",
            "gpu": "RTX 4080",
            "ram": "32GB DDR5",
            "storage": "1TB NVMe"
        },
        "image": "https://http2.mlstatic.com/D_NQ_NP_2X_646377-MCO107738700817_022026-T.webp"
    },
    {
        "id": 9,
        "name": "PC Workstation Pro",
        "category": "Prebuilt PC",
        "brand": "SMARTECH",
        "price": 7200000,
        "stock": 4,
        "specs": {
            "cpu": "Ryzen 9 7900X",
            "gpu": "RTX 4070",
            "ram": "64GB",
            "storage": "2TB SSD"
        },
        "image": "https://makemypc.com.au/image/pkg/workstation%20pro.png"
    },
    {
        "id": 10,
        "name": "Intel Core i5-13600K",
        "category": "CPU",
        "brand": "Intel",
        "price": 1450000,
        "stock": 20,
        "specs": {
            "cores": 14,
            "threads": 20,
            "base_clock": "3.5GHz",
            "boost_clock": "5.1GHz",
            "socket": "LGA1700"
        },
        "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcThjzvXvsAtWlEzcL3AR2bU4XHYLXG2WPfAjg&s"
    },
    {
        "id": 11,
        "name": "AMD Ryzen 7 7800X3D",
        "category": "CPU",
        "brand": "AMD",
        "price": 1950000,
        "stock": 12,
        "specs": {
            "cores": 8,
            "threads": 16,
            "base_clock": "4.2GHz",
            "boost_clock": "5.0GHz",
            "socket": "AM5"
        },
        "image": "https://www.amd.com/content/dam/amd/en/images/products/processors/ryzen/2505503-ryzen-7-7800x3d.jpg"
    },
    {
        "id": 12,
        "name": "Intel Core i7-14700K",
        "category": "CPU",
        "brand": "Intel",
        "price": 2100000,
        "stock": 18,
        "specs": {
            "cores": 20,
            "threads": 28,
            "base_clock": "3.4GHz",
            "boost_clock": "5.6GHz",
            "socket": "LGA1700"
        },
        "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSxtJah_dp9I8NGikMcytrcRJYPp9V45nPsuA&s"
    },
    {
        "id": 13,
        "name": "AMD Ryzen 5 7600X",
        "category": "CPU",
        "brand": "AMD",
        "price": 1100000,
        "stock": 25,
        "specs": {
            "cores": 6,
            "threads": 12,
            "base_clock": "4.7GHz",
            "boost_clock": "5.3GHz",
            "socket": "AM5"
        },
        "image": "https://themark.com.co/wp-content/uploads/2022/10/2079-500x500.png"
    },
    {
        "id": 14,
        "name": "NVIDIA RTX 4070 Ti Super",
        "category": "GPU",
        "brand": "NVIDIA",
        "price": 4200000,
        "stock": 9,
        "specs": {
            "memory": "16GB GDDR6X",
            "boost_clock": "2.61GHz",
            "ray_tracing": True
        },
        "image": "https://themark.com.co/wp-content/uploads/2024/12/4070-TI-SUPER-16-GB-NEGRA-1.jpg"
    },
    {
        "id": 15,
        "name": "AMD Radeon RX 7900 XTX",
        "category": "GPU",
        "brand": "AMD",
        "price": 4800000,
        "stock": 7,
        "specs": {
            "memory": "24GB GDDR6",
            "boost_clock": "2.5GHz",
            "ray_tracing": True
        },
        "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRqDX-dWut0wKI7EXVGcqoH2S3hEgAYRxlyxw&s"
    },
    {
        "id": 16,
        "name": "NVIDIA RTX 4060 8GB",
        "category": "GPU",
        "brand": "NVIDIA",
        "price": 1650000,
        "stock": 15,
        "specs": {
            "memory": "8GB GDDR6",
            "boost_clock": "2.46GHz",
            "ray_tracing": True
        },
        "image": "https://www.pcware.com.co/wp-content/uploads/2023/12/4473_001.jpg"
    },

    {
        "id": 17,
        "name": "ASUS TUF Gaming OC RTX 4070",
        "category": "GPU",
        "brand": "ASUS",
        "price": 3200000,
        "stock": 11,
        "specs": {
            "memory": "12GB GDDR6X",
            "boost_clock": "2.55GHz",
            "ray_tracing": True
        },
        "image": "https://http2.mlstatic.com/D_NQ_NP_919281-MLU72829797955_112023-O.webp"
    },

    {
        "id": 18,
        "name": "G.Skill Trident Z5 Neo 64GB",
        "category": "RAM",
        "brand": "G.Skill",
        "price": 1150000,
        "stock": 10,
        "specs": {
            "type": "DDR5",
            "speed": "6000MHz",
            "modules": "2x32GB"
        },
        "image": "https://http2.mlstatic.com/D_Q_NP_2X_640695-MLA100033472047_122025-P.webp"
    },

    {
        "id": 19,
        "name": "Kingston FURY Beast 16GB",
        "category": "RAM",
        "brand": "Kingston",
        "price": 320000,
        "stock": 40,
        "specs": {
            "type": "DDR4",
            "speed": "3200MHz",
            "modules": "2x8GB"
        },
        "image": "https://jesistem.com/wp-content/uploads/2024/11/FURY_Beast_RGB_Black_DDR4_1-zm-lg-600x600.jpg.webp"
    },

    {
        "id": 20,
        "name": "Crucial Pro 32GB Kit",
        "category": "RAM",
        "brand": "Crucial",
        "price": 540000,
        "stock": 15,
        "specs": {
            "type": "DDR5",
            "speed": "5600MHz",
            "modules": "2x16GB"
        },
        "image": "https://http2.mlstatic.com/D_NQ_NP_834685-MCO76384468173_052024-O.webp"
    },
      {
        "id": 21,
        "name": "TeamGroup T-Force Delta 32GB",
        "category": "RAM",
        "brand": "TeamGroup",
        "price": 590000,
        "stock": 20,
        "specs": {
            "type": "DDR5",
            "speed": "6400MHz",
            "modules": "2x16GB"
        },
        "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSy6leCyEbvEzI0Kp07jAL9CxsPO7QKPOCAqQ&s"
    },
    {
        "id": 22,
        "name": "WD Black SN850X 1TB",
        "category": "SSD",
        "brand": "Western Digital",
        "price": 520000,
        "stock": 22,
        "specs": {
            "type": "NVMe PCIe 4.0",
            "read_speed": "7300MB/s",
            "write_speed": "6300MB/s"
        },
        "image": "https://http2.mlstatic.com/D_NQ_NP_977509-MLA53364030390_012023-O.webp"
    },
    {
        "id": 23,
        "name": "Crucial P5 Plus 2TB",
        "category": "SSD",
        "brand": "Crucial",
        "price": 780000,
        "stock": 18,
        "specs": {
            "type": "NVMe PCIe 4.0",
            "read_speed": "6600MB/s",
            "write_speed": "5000MB/s"
        },
        "image": "https://http2.mlstatic.com/D_Q_NP_761798-CBT52322601895_112022-O.webp"
    },
    {
        "id": 24,
        "name": "Kingston NV2 1TB",
        "category": "SSD",
        "brand": "Kingston",
        "price": 280000,
        "stock": 50,
        "specs": {
            "type": "NVMe PCIe 4.0",
            "read_speed": "3500MB/s",
            "write_speed": "2100MB/s"
        },
        "image": "https://http2.mlstatic.com/D_Q_NP_761798-CBT52322601895_112022-O.webp"
    },
    {
        "id": 25,
        "name": "MSI Spatium M480 2TB",
        "category": "SSD",
        "brand": "MSI",
        "price": 850000,
        "stock": 14,
        "specs": {
            "type": "NVMe PCIe 4.0",
            "read_speed": "7000MB/s",
            "write_speed": "6800MB/s"
        },
        "image": "https://storage-asset.msi.com/global/picture/image/feature/storage/spatium_m480-hs/spatium-m480-hs-kv.png"
    },
    {
        "id": 26,
        "name": "MSI MAG Z790 Tomahawk WiFi",
        "category": "Motherboard",
        "brand": "MSI",
        "price": 1450000,
        "stock": 10,
        "specs": {
            "socket": "LGA1700",
            "chipset": "Z790",
            "ram_support": "DDR5"
        },
        "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRnvY2vCSLnfMAUMFhUGE6CAoZ2aP7iGwY18A&s"
    },
    {
        "id": 27,
        "name": "Gigabyte B650 AORUS ELITE AX",
        "category": "Motherboard",
        "brand": "Gigabyte",
        "price": 1100000,
        "stock": 15,
        "specs": {
            "socket": "AM5",
            "chipset": "B650",
            "ram_support": "DDR5"
        },
        "image": "https://jesistem.com/wp-content/uploads/2024/10/B650-AORUS-ELITE-AX.webp"
    },
    {
        "id": 28,
        "name": "ASRock Z790 Steel Legend",
        "category": "Motherboard",
        "brand": "ASRock",
        "price": 1280000,
        "stock": 7,
        "specs": {
            "socket": "LGA1700",
            "chipset": "Z790",
            "ram_support": "DDR5"
        },
        "image": "https://http2.mlstatic.com/D_NQ_NP_778635-MLU75322281149_032024-O.webp"
    },
    {
        "id": 29,
        "name": "ASUS PRIME H610M-E",
        "category": "Motherboard",
        "brand": "ASUS",
        "price": 450000,
        "stock": 30,
        "specs": {
            "socket": "LGA1700",
            "chipset": "H610",
            "ram_support": "DDR4"
        },
        "image": "https://dlcdnwebimgs.asus.com/gain/58304d96-dc0e-4367-988b-7c1b2744f147/w692"
    },
    {
        "id": 30,
        "name": "EVGA SuperNOVA 1000G P6",
        "category": "Power Supply",
        "brand": "EVGA",
        "price": 980000,
        "stock": 5,
        "specs": {
            "certification": "80+ Platinum",
            "modular": True
        },
        "image": "https://www.vortez.net/news_file/21780_evga-supernova-p6-1000-box.jpg"
    }
]