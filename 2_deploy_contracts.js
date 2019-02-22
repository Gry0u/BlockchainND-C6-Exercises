const ExerciseC6A = artifacts.require('./ExerciseC6A.sol')
const ExerciseC6C = artifacts.require('./ExerciseC6C.sol')
const ExerciseC6CApp = artifacts.require('./ExerciseC6CApp.sol')

module.exports = function (deployer) {
  deployer.deploy(ExerciseC6A)
  deployer.deploy(ExerciseC6C)
  deployer.deploy(ExerciseC6CApp)
}
