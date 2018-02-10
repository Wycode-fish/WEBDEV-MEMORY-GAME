import React from 'react';
import ReactDom from 'react-dom';
import { Button } from 'reactstrap';

export default function init(root, channel) {
	ReactDom.render(<MemoryMaster channel={channel} />, root);
}

/*
	memory-master states:
	{
		tiles: [List of Tile],
		click: Int
	}

	A Tile item is:
	{ letter: String, selected: Bool, matched: Bool, id: Int}
*/

class MemoryMaster extends React.Component {

	constructor(props) {
		super(props);
		this.channel = props.channel;
		this.state = {
			matchedTilesIds:[],
			selectedTilesIds:[],
			score:100,
			clickNum:0,
			tileList:[],
		};
		console.log ("in constructor");
		this.channel.join()
		.receive("ok", this.returnedStateFromServer.bind(this))
		.receive("error", resp => 
			{console.log("unable to join ",resp)});
	}

	letterCount(){
		return this.state.tileList.length/2;
	}


	returnedStateFromServer(props) {
		let state = props.game;
		console.log("returned state", props);
		//this.winGame();
		this.setState(state);
		if (this.state.selectedTilesIds.length == 2){
			this.sendTimeoutToServer();
		}
		this.winGame();
	}

	winGame () {
		console.log("winGame: "+this.state.matchedTilesIds.length+" "+this.letterCount());
		let finish = 
			this.state.matchedTilesIds.length == this.letterCount()*2;
		if (finish) {
			let score = this.state.score;
			if (confirm("score:  "+Math.round(score)+"/100. Press Enter to restart.")){
				this.sendRestartToServer();
			}
		}
	}

	sendGuessToServer(ev, id) {
		this.channel.push("guess", {tile_id: id})
		.receive("ok", this.returnedStateFromServer.bind(this));
	}

	sendRestartToServer(ev) {
		this.channel.push("restart", {})
		.receive("ok", this.returnedStateFromServer.bind(this));
	}

	sendTimeoutToServer() {
		let that = this;
		console.log("selected: "+this.state.selectedTilesIds.length);
		setTimeout(function(){
			that.afterDelay();
		}, 1000);
	}

	afterDelay() {
		this.channel.push ("timeout", {})
			.receive("ok", this.returnedStateFromServer.bind(this));
	}
	render() {

		let tileList = _.map (this.state.tileList, (t, ii)=>{
			console.log("tile: "+t.letter);
			return <Tile tile={t} clickTile={this.sendGuessToServer.bind(this, t.id)} key={ii}/>;
		})
		console.log("---");
		console.log(this.state.tileList);
		return (
			<div>
				<ul>
					{tileList.slice(0, 4)}
				</ul>
				<ul>
					{tileList.slice(4, 8)}
				</ul>
				<ul>
					{tileList.slice(8, 12)}
				</ul>
				<ul>
					{tileList.slice(12, 16)}
				</ul>
				<InfoBar state={this.state}/>
				<RestartBtn root={this} restart={this.sendRestartToServer.bind(this)}/>
			</div>
		);
	}

/*
	setClick (id) {
		// no matter what, set the tile selected
		let currSelected = this.selectedLetters();
		if (currSelected.length<2){
			this.flipTile(id);
		}
		
		// determine behaviors.
		let selecteds = this.selectedLetters();
		console.log(selecteds.length);
		if (selecteds.length==2){
			if (selecteds[0]==selecteds[1]){
				let lmatch = _.map(this.tiles(), (t) => {
					if (t.letter==selecteds[0]){
						return _.extend(t, {
							selected:false,
							matched:true,
						});
					}
					else return t;
				});
				let st2 = _.extend(this.state, {
					tiles:lmatch,
				})
				this.setState(st2);
				this.winGame();
			}
			else {
				let that = this;
				setTimeout(function(){
					that.deselectAll();
				},1000);
				
			}
		}
		
	}

	deselectAll () {
		let deselected = _.map(this.tiles(), (t)=>{
			return _.extend(t, {
				selected:false
			});
		});
		let st = _.extend(this.state, {
			tiles: deselected,
		});
		this.setState(st);
	}

*/	


}

function InfoBar (props) {
	let state = props.state;
	let matchedNum = state.matchedTilesIds.length/2;
	let cl = state.clickNum;
	return (<div>
		<span className="click">Clicks: {cl} </span>
		<span className="match">Match: {matchedNum}</span>
	</div>);
}

function RestartBtn (props) {
	return <span className="restart">
	<Button onClick={()=>props.restart()}>Restart</Button>
	</span>
}

function Tile (props) {
	let show = false;
	let tile = props.tile;
	if (tile.matched || tile.selected) {
		show=true;
	}
	if (show) return <li><Button className="selected">{tile.letter}</Button></li>;
	else return <li><Button className="unselected" onClick={()=>props.clickTile(tile.id)}></Button></li>;
}


