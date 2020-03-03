---
layout:     post
title:  docker进阶
subtitle: docker进阶
date:       2020-1-30
author:     silence
header-img: img/post-linux.png
catalog: true
tags:
    - linux
    - openstack
---



### OpenStack的组件:

OpenStack的API风格为：RESTful，它可以兼容AWS(亚马逊云)、S3；即Openstack可直接调用AWS或S3上的应用，
也可以直接在AWS、S3上调用OpenStack的应用；可非常方便的组件混合云。
核心组件：

　　1. 服务名:Compute(代码名:Nova) :它主要用来管理VM实例的完整生命周期,启动、资源分配、关闭、销毁、运行中SSH密钥注入、SSH连接的提供等，均由它来提供。
　　2.服务名:Networking(代码名:Neutron):早期由Nova,即Compute来提供，从F版(Folsom release)开始独立出来,用于提供网络连接服务，它采用插件设计,支持众多流行的网络管理插件.
　　3.Storage ：分两个组件，一个为Block存储(Cinder), 另一个为对象存储(Swift)
　　　　对象存储：类似于VMware的磁盘文件,但VMware的磁盘文件并非是对象存储,对象存储是自身包含自身的元数据，即便将它放到一个没有文件系统的磁盘上，它也能自我管理。OpenStack采用Swift这个重量级的分布式存储系统,是因为开发该系统的公司是OpenStack的早期发起人之一,并且该公司还将自己的分布式存储系统贡献给OpenStack作为其对象存储系统,该系统就是Swift。
　　Object Storage: 代码名:Swift,它是通过RESTful接口来存储和检索非结构化的数据对象，它是一个高容错可伸缩的存储架构。
　　Block Storage：代码名:Cinder,早期由Nova,即Compute组件来提供,从F版开始独立出来,它主要为VM提供持久的块存储的组件。
4. Identify，代码名: Keystore ,它为除自身外的其它所有组件提供了一个认证和授权的服务及端点编录服务,即类似与目录服务的功能,可通过它检索所有组件的访问路径。
5. Image，代码名：Glance，它是作为Swift的前端,用来提供存储对象元数据检索的,简单说:即VM启动前需要知道磁盘镜像文件存在哪,它就需要访问Image服务来检索,Image服务上存储了所有Swift的存储位置信息，它会告诉VMclient到哪去下载镜像,然后,VMclient再自己去找。
6. Dashboard（用户交互界面）(Horizon) ：它是一个与OpenStack个组件交互的基于Web的访问接口。
7. Telemetry,代码名:Ceilometer, 监控和计量VM,计量:即根据用户使用VM的资源来收费,如:你使用了多少RAM、CPU、网络带宽、磁盘空间等等。
8. Orachestration:代码名:Heat, 基于模板格式或AWS的CloudFormation模板格式来实现快速将多个资源联动起来,完成统一服务功能.简单理解:基于模板来实现系统管理.
9. Database: 代码名:Trove, 用来提供DBaaS的组件。
10.Data processing: 代码名:Sahara(沙哈拉), 用于在OpenStack中实现Hadoop的按需可伸缩的管理。